#!/usr/bin/env python

import os
import sys
import getopt
import shutil
import logging
import ConfigParser 

def parse_config(fname):
    if not os.path.exists(fname):
        return None

    try:    
        conf = ConfigParser.ConfigParser()
        conf.read(fname)
    except:
        conf = None
    return conf

def run_command(cmd, *args): 
    if not cmd:
        return ''
    if args:
        cmd = ' '.join((cmd,) + args) 
        print "[INFO] %s" % cmd

    try:
        import subprocess
    except ImportError: # Python 2.3
        _, rf, ef = os.popen3(cmd)
    else: # Python 2.4+
        p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        rf, ef = p.stdout, p.stderr
    errors = ef.read()
    if errors: 
        print "ERROR: %s" % errors 
    return rf.read().strip()


def get_item(conf, section, key):
    try:
        value = conf.get(section, key)
    except:
        value = ""
    return value

def run_object(conf, section, prog):
    opt = get_item(conf, section, "opt")
    env = get_item(conf, section, "env")
    img = get_item(conf, section, "img")
    cmd = get_item(conf, section, "cmd")
    if img and prog:
        run_command("docker", prog, opt, env, img, cmd)

def info_object(conf, section):
    opt = get_item(conf, section, "opt")
    env = get_item(conf, section, "env")
    img = get_item(conf, section, "img")
    cmd = get_item(conf, section, "cmd")
    print "opt=%s\nenv=%s\nimg=%s\ncmd=%s" % (opt, env, img, cmd)
    print

def list_objects(conf):
    if not conf: 
        return
    index = 0
    for sec in conf.sections():
        print "[%d] %s" % (index, sec)
        index = index + 1
    print

def usage():
    #prog = os.path.basename(sys.argv[0])
    prog = "run-docker"
    print "%s [-h | -l | -i image | image1 [image2 ..]]" % prog
    print "     -h|--help:          help"
    print "     -c|--config:        generate <$HOME/.docker.ini> if not exists"
    print "     -l|--list:          list available objects"
    print "     -i|--info image:    list image's config"
    print "     First read config <$HOME/.docker.ini> if not exist, then use default."
    print

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        usage()
        sys.exit(1)

    fname1 = "%s/.docker.ini" % os.getenv("HOME")
    conf = parse_config(fname1)
    if not conf:
        dname = os.path.dirname(sys.argv[0])
        if not dname: 
            dname = "."
        elif dname[0] != "/":
            dname = "./%s" % dname
        fname2 = "%s/docker.ini" % dname
        conf = parse_config(fname2)
    if not conf:
        print "[ERROR] no default config docker.ini\n"
        sys.exit(1)
    
    try:
        sopts = "hlci:"
        lopts = ["help", "list", "config", "info="]
        options, args = getopt.getopt(sys.argv[1:], sopts, lopts)
    except getopt.GetoptError:
        usage()
        sys.exit(1)

    is_exit = False
    for name, value in options:
        if name in ("-h", "--help"):
            usage()
            is_exit = True
        elif name in ("-l", "--list"):
            list_objects(conf)
            is_exit = True
        elif name in ("-i", "--info"):
            info_object(conf, value)
            is_exit = True
        elif name in ("-c", "--config"):
            shutil.copy(fname2, fname1)
            is_exit = True
    if is_exit:
        sys.exit(0)

    if not args or len(args) < 1: 
        usage()
        sys.exit(1)

    for arg in args:
        run_object(conf, arg, "run")
        print

    sys.exit(0)
