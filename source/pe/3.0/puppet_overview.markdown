---
layout: default
title: "PE 3.0 » Puppet » Overview"
subtitle: "An Overview of Puppet"
---

<!-- todo we could use something talking about what declarative configuration management is. -->

Where Configurations Come From
-----

Configurations for nodes are compiled from [**manifests**](/learning/manifests.html), which are documents written in Puppet's custom language. Manifests declare [**resources**](/learning/ral.html), each of which represents the desired state of some _thing_ (software package, service, user account, file...) on a system. Resources are grouped into [**classes**](/learning/modules1.html#classes), and classes are grouped into [**modules**](/learning/modules1.html#modules). Modules are structured collections of manifest files, with each file containing a single class (or defined type).


How Configurations are Assigned to Nodes
-----

In Puppet Enterprise, the console controls which classes are assigned to nodes. You can assign classes and class parameters to nodes individually, or you can collect nodes into groups and configure a large number of nodes in a single page. You can also declare variables that can be read by any of the classes assigned to a node.

> To see how to assign configurations to nodes in the PE console, see [the Grouping and Classifying Nodes page](./console_classes_groups.html) in the console section of this manual.

When an agent node requests its catalog from the master, the master asks the console which classes and parameters to use, then compiles those classes into the node's catalog.

What Nodes Do With Catalogs
-----

The heart of Puppet is the resource abstraction layer (RAL), which lets the puppet agent turn abstract resource declarations into concrete actions specific to the local system. Once the agent has its catalog of resource declarations, it uses the system's own tools to bring those resources into their desired state.

When New Configurations Take Effect
-----

By default, puppet agent will pull a catalog and run it every 30 minutes (counted from when the agent service started, rather than on the half-hour). You can change this by setting the [`runinterval`](/references/3.2.latest/configuration.html#runinterval) option in an agent's [`/etc/puppetlabs/puppet/puppet.conf`](/guides/configuring.html) file to a new value. (The `runinterval` is measured in seconds.)

If you need a node or group of nodes to retrieve a new configuration _now,_ [use the orchestration engine to trigger a Puppet run on any number of nodes](./orchestration_puppet.html). You can also run a large number of nodes in a controlled series from the puppet master's command line; [see this section of the Orchestration: Controlling Puppet page](./orchestration_puppet.html#run-puppet-on-many-nodes-in-a-controlled-series) for details.


* * *

- [Next: Puppet Tools](./puppet_tools.html)