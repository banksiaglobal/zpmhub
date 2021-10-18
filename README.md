# ZpmHub by Banksia Global
[ZpmHub](https://zpmhub.com/) is a private ZPM Registry and environment monitoring solution built by [Banksia Global](https://banksiaglobal.com/) consulting agency.

This package allows you to publish, list and deploy packages, as well as push environment statistics to ZpmHub.

## Prerequisites
ZpmHub works only on IRIS and IRIS For Health, community and Enterprise versions. You need to have ZPM Package manager installed.

# Installation

## ZpmHub registration

To use ZpmHub, you'll need your user name and password registered on [ZpmHub](https://zpmhub.com/). If you haven't done so yet, please register there.

## Installing zpm
You need to have zpm package manager available on your IRIS instance first. You can check if zpm is installed on your system by issuing the following command in your IRIS terminal:

    USER>zpm "version"

If you see output like this

    %SYS> zpm 0.3.0
it means that zpm is already installed and you can go to the next step. If you see output like this

```
ZPM "version"
^
<SYNTAX>
```
you need to install zpm.

To install ZPM you can either manually download and import the latest release from https://github.com/intersystems-community/zpm, or use this one-liner in Terminal to do it programmatically:

    zn "%SYS" d ##class(Security.SSLConfigs).Create("zpm") s r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="zpm" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")


## ZpmHub installation

Now you can install ZpmHub. In terminal, issue the following command:

    zpm "install zpmhub"

It will ask you to enter user name and password, and also if you want to enable monitoring for the current environment. 

# Usage

After installing zpmhub package, your remote repositoru will be changed to ZpmHub's one. You can use standard ZPM comands like "zpm publish" and "zpm install" to manage your deployments. Refer to [ZPM documentation](https://github.com/intersystems-community/zpm) for more information.