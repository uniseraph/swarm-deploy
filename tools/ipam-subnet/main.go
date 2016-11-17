package main

import (
	"flag"
	"os"
	"fmt"
	"github.com/coreos/flannel/version"
	"github.com/coreos/flannel/subnet"
	"strings"
	log "github.com/golang/glog"
	"golang.org/x/net/context"

	"github.com/coreos/flannel/pkg/ip"
)

type MyCmdLineOpts struct {
	etcdEndpoints  string
	etcdPrefix     string
	etcdKeyfile    string
	etcdCertfile   string
	etcdCAFile     string
	etcdUsername   string
	etcdPassword   string
	localIP        string
	help           bool
	version        bool
	kubeSubnetMgr  bool
}

var opts MyCmdLineOpts

func init() {
	flag.StringVar(&opts.etcdEndpoints, "etcd-endpoints", "http://127.0.0.1:4001,http://127.0.0.1:2379", "a comma-delimited list of etcd endpoints")
	flag.StringVar(&opts.etcdPrefix, "etcd-prefix", "/coreos.com/network", "etcd prefix")
	flag.StringVar(&opts.etcdKeyfile, "etcd-keyfile", "", "SSL key file used to secure etcd communication")
	flag.StringVar(&opts.etcdCertfile, "etcd-certfile", "", "SSL certification file used to secure etcd communication")
	flag.StringVar(&opts.etcdCAFile, "etcd-cafile", "", "SSL Certificate Authority file used to secure etcd communication")
	flag.StringVar(&opts.etcdUsername, "etcd-username", "", "Username for BasicAuth to etcd")
	flag.StringVar(&opts.etcdPassword, "etcd-password", "", "Password for BasicAuth to etcd")
	flag.StringVar(&opts.localIP,"local-ip","192.168.3.19","Local IP used to connect etcd")
	flag.BoolVar(&opts.kubeSubnetMgr, "kube-subnet-mgr", false, "Contact the Kubernetes API for subnet assignement instead of etcd or flannel-server.")
	flag.BoolVar(&opts.help, "help", false, "print this message")
	flag.BoolVar(&opts.version, "version", false, "print version and exit")
}

func main() {

	// glog will log to tmp files by default. override so all entries
	// can flow into journald (if running under systemd)
	flag.Set("logtostderr", "true")

	// now parse command line args
	flag.Parse()

	if flag.NArg() > 0 || opts.help {
		fmt.Fprintf(os.Stderr, "Usage: %s [OPTION]...\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(0)
	}

	if opts.version {
		fmt.Fprintln(os.Stderr, version.Version)
		os.Exit(0)
	}

	cfg := &subnet.EtcdConfig{
		Endpoints: strings.Split(opts.etcdEndpoints, ","),
		Keyfile:   opts.etcdKeyfile,
		Certfile:  opts.etcdCertfile,
		CAFile:    opts.etcdCAFile,
		Prefix:    opts.etcdPrefix,
		Username:  opts.etcdUsername,
		Password:  opts.etcdPassword,
	}

	sm , err := subnet.NewLocalManager(cfg)

	if err!=nil{
		log.Error("Failed to create SubnetManager: ", err)
		os.Exit(1)
	}


	ctx ,cancel:= context.WithCancel(context.Background())



	addr , _ :=ip.ParseIP4(opts.localIP)
	attrs := &subnet.LeaseAttrs{
		PublicIP:addr,
		BackendType:"vxlan",
	}
	l , err := sm.AcquireLease(ctx, "" , attrs )

	cancel()
	if err!=nil {
		log.Error("Failed to get a lease:" , err)
		os.Exit(1)
	}


	fmt.Print(l.Subnet.String()+" ")
	l.Subnet.IP = l.Subnet.IP + 1
	fmt.Print(l.Subnet.String())
}
