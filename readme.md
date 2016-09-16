# Introduction

This is a guide to get the Red Hat 2016 Summit game up and running within a CDK environment. It is highly recommended that you view the demo of the game that was done at the 2016 Red Hat Summit [here](https://www.youtube.com/watch?v=ooA6FmTL4Dk) to understand what the game is about. As a summary, the game is a balloon popping game where the attendees can participate by playing the game while the demo is running. The game is a great demo for OpenShift and DevOps and makes use of a number of other Red Hat products including BRMS and EAP.

In order to build this demo you will need access to the Keynote repositories in github, please contact Burr Sutter for that.

Note that this game uses a microservice architecture and  requires quite a few pods to run, thus it is recommended that you allocated additional memory to the CDK in the Vagrant file. This guide was developed using 8 GB allocated to the CDK with 16 GB of system memory. 

Finally, this guide assumes you are using a Linux system, some instructions may vary for Windows and Mac OSX.

# Game Repositories

As mentioned previously, the game consists of a number of repositories in github, 21 in total in fact. This guide builds a subset of the game: the basic game plus the administration app, scoreboard, leaderboard and achievements are all function. This guide does not cover the Pipeline and CICD functionality that was demonstrated in the video. At the moment the following repositories are used:

Repository        | Fork           | Local Clone Required|Description  |
| ------------- |:-------------:| -----:|
[templates](https://github.com/Red-Hat-Middleware-Keynote/templates)|[templates](https://github.com/gnunn1/templates)|Yes|These are the OpenShift templates required for the various game components. Note that some of these templates were not maintained as they were shifted to the cicd-templates however the template for the mobile game comes from here.
[cicd-templates](https://github.com/Red-Hat-Middleware-Keynote/cicd-templates)|[cicd-templates](https://github.com/gnunn1/cicd-templates)|Yes|These are the templates used for the components that support CICD . Even though this guide is not getting into the CICD components these templates are used as they were current compared to the equivalents in the templates repository. This repository was forked to fix a few minor issues plus allow the number of replicas to be specified as a parameter. Finally the templates were altered to use readily available images. The templates in the original repo reference derived images that pre-fetched Maven dependencies. 
[vertx-game-server](https://github.com/Red-Hat-Middleware-Keynote/vertx-game-server)| | |The game server that acts as an integration bus for the other microservices. The game, leaderboard and scoreboard all connect to this in order to communicate with the other components. As the name implies, this component uses the [Vert.X](http://vertx.io/) framework.
[mobile-app](https://github.com/Red-Hat-Middleware-Keynote/mobile-app)| | |This is the actual game, it is a game written in typescript using angular. It communicates both with it's own back-end server as well as the vertx-game-server.
[mobile-app-admin](https://github.com/Red-Hat-Middleware-Keynote/mobile-app-admin)| |Yes|This is the tool to administer the game, without this app you cannot start the game. This component does not run in OpenShift, instead it is run locally on your laptop or in Amazon EC2/S3, it requires connectivity to the vertx-game-server.
[game-mechanics](https://github.com/Red-Hat-Middleware-Keynote/game-mechanics-server)| | |This component manages the game configuration, it is written in Java with Wildfly Swarm.
[achievement-server](https://github.com/Red-Hat-Middleware-Keynote/achievement-server)| | | Manages the player achievements, it is a JEE application that runs on EAP (or Wildfly)
[score-server](https://github.com/Red-Hat-Middleware-Keynote/score-server)|[score-server](https://github.com/gnunn1/score-server)| | Aggregates the player scores, runs on BRMS and uses rules to evaluate scoring. This was forked to fix a build issue as a dependency on hibernate-core was needed to compile the hibernate annotations.
[leaderboard](https://github.com/Red-Hat-Middleware-Keynote/leaderboard)| |Yes| A javascript application that is run outside of OpenShift to display the leaderboard. It requires connectivity to the vertx-game-server.
[scoreboard](https://github.com/Red-Hat-Middleware-Keynote/scoreboard)| |Yes| A javascript application that is run outside of OpenShift to display the scoreboard. It requires connectivity to the vertx-game-server.

# Pre-Steps

Prior to setting up the game itself, there are a number of pre-steps that must be completed first.

### Install the CDK

This guide was built using the Red Hat CDK 2.1, this needs to be install and configured as per the [instructions](https://access.redhat.com/documentation/en/red-hat-container-development-kit/2.0/single/installation-guide) on the Red Hat site.

### Install npm and angiular-cli

Some of the applications that are run locally depend on npm and angular-cli. Install npm using the appropriate package for your distro. Once npm is installed, you can install angular-cli with the following command:

```
sudo npm install -g angular-cli
```

Note for angular-cli the applications require the 1.0 version.

Longer term we'll look at  moving these apps into OpenShift and the CDK.

### Clone Required Repositories

In order to use this guide, some of the repositories must be cloned to your laptop. In the preceeding table, the repositories marked as **Yes** in the **Local Clone Required** are the ones to clone. This can be done by using the following instructions:

```
mkdir <some_directory>
cd <some_directory>
git clone https://github.com/gnunn1/templates
git clone https://github.com/gnunn1/cicd-templates
git clone https://github.com/Red-Hat-Middleware-Keynote/mobile-app-admin
git clone https://github.com/Red-Hat-Middleware-Keynote/leaderboard
git clone https://github.com/Red-Hat-Middleware-Keynote/scoreboard
```

### Configure Host File

The game is configured to use specific DNS entries, rather then setup a DNS system in Vagrant (via landrush or some other plugin) I simply opted to add some entries to the /etc/hosts file on my local laptop. The required entries are as follows:

```
10.1.2.2	gamebus-production.apps-test.redhatkeynote.com	gamebus-production
10.1.2.2	gamebus-boards-production.apps-test.redhatkeynote.com  gamebus-boards-production.apps-test
10.1.2.2	game-server-demo.rhel-cdk.10.1.2.2.xip.io
10.1.2.2	game-app-demo.rhel-cdk.10.1.2.2.xip.io
```

### Docker Images

There are two docker images that must be built first as follows:

* s2i-vertx: This docker image for the s2i build for vertx-game-server which uses the vertx framework.
* s2i-nginx-nodejs: The docker image for the s2i build for the mobile-app

The first steps are done on your host system, we will leverage the fact that Vagrant automatically mounts directories where the Vagrantfile is located. 


```
cd {CDK_INSTALL_DIRECTORY}/component/rhel/rhel_ose
github clone https://github.com/cescoffier/vertx-s2i
github clone https://github.com/detiber/s2i-nginx-nodejs
vagrant up
vagrant ssh
```

You are now SSH'ed to the vagrant CDK instance. First build the s2i-vertx image:

```
cd /vagrant/vertx-s2i
sudo make
```
You may get an error when building this image saying there is a problem with the manifest. This is because this image references a centos image that was build with Docker 10 and uses the a new schema versus 9. The easiest solution is too simply update the image to use the openshift/base-centos7 image instead.

Next we will build the s2i-nginx-nodejs instance, note that building this image requires access to RHEL repositories that require a subscription. You may need to register the CDK with a subscription to build this image.

```
cd /vagrant/s2i-nginx-nodejs
sudo make
```
The password for sudo in the vagrant box is ```vagrant```. Note that this build will take quite a while as it configures repos and installs various packages in the docker image, be patient.

Now that the docker images are created, we will move on to the next steps so exit the ssh session or open a new terminal on your host.

### Configure Environment Script

On your host system, change to the directory where you installed the binary scripts. Edit the file setenv.sh and modify the GITHUB_USER and GITHUB_PW environment variables to match your github username and password. Note these credentials must have access to the [Keynote](https://github.com/Red-Hat-Middleware-Keynote) github repository.

You also need to include the registry URL for your OpenShift installation. In the CDK you can get this via oc:

```
oc get svc -n default
```

### Create OpenShift Project

On your host system, run the following commands to create the project:

```
oc login 10.1.2.2:8443
./cdkCreateproject.sh
```

Confirm in the OpenShift console that the ```demo``` project has been created.

### Tag and Push Docker Images

Go back to your vagrant ssh session or start a new one. We now need to tag and push the images to the OpenShift repository. Longer term the goal would be to get these images uploaded to a public registry or docker.io so they do not need to be created manually.

In your vagrant ssh session, run the following commands to login to OpenShift determine the ip and port of the ```docker-registry``` in your CDK:

```
oc login 10.1.2.2:8443
oc get svc -n default
```

To push the images to the OpenShift registry you will need to have docker login to it first. This will require a change to the docker configuration in order to allow it to use an insecure registry:

```
sudo nano /etc/sysconfig/docker

```

Find the following line:

```
 # INSECURE_REGISTRY='--insecure-registry'
```
And change it to:
```
INSECURE_REGISTRY='--insecure-registry=<docker-registry ip:port>'
```

Save the file and restart the docker service. 

```
sudo systemctl restart docker.service
```

Now let's tag and push the images as follows:

```
sudo docker login -u admin -p $(oc whoami -t) <docker-registry ip:port>
docker tag vertx-s2i <docker-registry ip:port>/demo/vertx-s2i
docker tag s2i-nginx-nodejs <docker-registry ip:port>/demo/nginx-nodejs
sudo docker push <docker-registry ip:port>/demo/vertx-s2i
sudo docker push <docker-registry ip:port>/demo/nginx-nodejs
```

### Create Databases

The application depends on a postgresql database for the score and achievements applications. When deployed to Amazon this database is created using a persistent volume, however in the CDK we will use an epheremal template. To create the database, run the following:

```
./cdkDatabases.sh
```

Check the OpenShift console and make sure you see two databases created, score-postgresql and achievement-postgresql. Make sure they are fully built and deployed (i.e blue circles) before moving on to the next step.

# Create Applications

### Step 1 - Create game-mechanics Application

In this step we will create the game-mechanics server. it is responsible for synchronizing configuration changes.

```
./cdkMechanics.sh
```
Confirm that the game-mechanics server is built, deployed and running before proceeding to the next step. Note that in the forked cicd-templates script I have adjusted the replica to a value of 1, this should be parameterized in the future.

### Step 2 - Create achievements Application

Run the script ```cdkAchievementServer.sh``` to upload the achievements template and create a new app for it. Wait for it to build and deploy, this make take some time as it will download an image for JBoss EAP 7 which is quite large. Note that in the forked cicd-templates script I have adjusted the replica to a value of 1, this should be parameterized in the future.


### Step 3 - Create score Application

Run the script ```cdkScoreServer.sh`` to to upload the score server template and create a new app for it. Wait for it to build and deploy. Note that in the forked cicd-templates script I have adjusted the replica to a value of 1, this should be parameterized in the future.

### Step 4 - Create gamebus Application

Run the script ```cdkGameServer.sh``` to to upload the game server template and create a new app for it. Wait for it to build and deploy.

To confirm the application is up and accessible on your host laptop, enter the following URL in a browser:

```
gamebus-production.apps-test.redhatkeynote.com/health
```

You should see message saying something like there are 0 active users. Note that in the forked cicd-templates script I have adjusted the replica to a value of 1, this should be parameterized in the future.

### Step 5 - Create the game-app Application

In this step we create an application in OpenShift for the mobile game. To do so, run the ```cdkGameApp.sh``` script. Wait for the application to build and deploy. To access the game, use the following URL on your host laptop:

```
game-app-demo.rhel-cdk.10.1.2.2.xip.io
```

Note that you cannot actually play the game until you start the game in the administration application.


### Step 6 - Run the mobile-app-admin locally

Run the mobile-app-admin by doing the following:

```
git clone https://github.com/Red-Hat-Middleware-Keynote/mobile-app-admin
cd mobile-app-admin
ng build
ng serve -prod
```

Access the admin at localhost:4200 in a browser, the password is ```CH2UsJePthRWTmLI8EY6```. This password is found in vertx-game-server/src/main/groovy/GameVerticle.groovy file.

Once you are logged in, click the start button to allow people to play the game. Confirm this by running the game in your browser as per Step 5.

### Step 7 - Play the mobile game

At this point you should be able to play the game in your browser. Access the URL ```http://game-app-demo.rhel-cdk.10.1.2.2.xip.io``` and play the game. After popping a few balloons check the achievements tab to view achievements.

### Step 8 - View the scoreboard

To view the scoredboard first clone it from the repository:

```
git clone https://github.com/Red-Hat-Middleware-Keynote/scoreboard
```

And then open the file scoreboard/index.html in a browser. The scoreboard is a pure javascript application.

### Step 9 - View the leaderboard

To view the leaderboard first clone it from the repository:

```
git clone https://github.com/Red-Hat-Middleware-Keynote/leaderboard
```

And then open the file leaderboard/index.html in a browser. The leaderboard is a pure javascript application.