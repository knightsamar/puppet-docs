---
layout: default
title: "PE 2.8  » Cloud Provisioning » Troubleshooting"
subtitle: "Finding Common Errors"
---

Troubleshooting
---------------

### Missing .fog File or Credentials

If you attempt to provision without creating a `.fog` file or without
populating the file with appropriate credentials you'll see the following error:

On VMware:

    $ puppet node_vmware list
    notice: Connecting ...
    err: Missing required arguments: vsphere_username, vsphere_password, vsphere_server
    err: Try 'puppet help node_vmware list' for usage

On Amazon Web Services:

    $ puppet node_aws list
    err: Missing required arguments: aws_access_key_id,
    aws_secret_access_key
    err: Try 'puppet help node_aws list' for usage

Add the appropriate file or missing credentials to the existing file to resolve
this issue.

Note that versions of fog newer than 0.7.2 may not be fully compatible with Cloud Provisioner. This issue is currently being investigated.

### Certificate Signing Issues

#### Accessing Puppet Master Endpoint

For automatic signing to work, the computer running Cloud Provisioner (i.e. the CP control node) needs to be able to access the puppet master's `certificate_status` REST endpoint. This can be done in the master's [auth.conf](http://docs.puppetlabs.com/guides/rest_auth_conf.html) file as follows:

     path /certificate_status
     method save
     auth yes
     allow {certname}

Note that if the CP control node is on a machine other than the puppet master, it must be able to reach the puppet master over port 8140.

#### Generating Per-user Certificates

The CP control node needs to have a certificate that is signed by the puppet master's CA. While it's possible to use an existing certificate (if, say, the control node was or is an agent node), it's preferable to generate a per-user certificate for a clearer, more explicit security policy.

Start by running the following on the control node:
`puppet certificate generate {certname} --ca-location remote`
Then sign the certificate as usual on the master (`puppet cert sign {certname}`). Lastly, back on the control node again, run:

     puppet certificate find ca --ca-location remote
     puppet certificate find {certname} --ca-location remote
     This should let you operate under the new certname when you run puppet commands with the --certname {certname} option.

 [Next: Compliance Basics](./compliance_basics.html) 

