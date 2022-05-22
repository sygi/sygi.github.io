---
title: 'Cloud computing'
---

In recent years, cloud computing became very popular: it is both used on single pages with CVs and governments' apps worth hundreds of millions. As I wanted to publish online a couple of smaller projects, I played with a number of cloud-based services to see how easy to use and costly are they for a hobby project.

## The cloud

One needs a lot of infrastructure to host a modern website. To exploit the economies of scale, big internet companies (Amazon, Google, Microsoft) offer to store other people's websites and to show them to their users. It is a win-win situation: big companies earn money while sharing their excessive storage and compute, and their customers don't have to manage dedicated hardware and worry about scaling issues.

The range of services related to website hosting is wide. Apart from the obvious: storing and sending the actual assets (HTML/JS/CSS files and images), to keep a website up one needs:

1. a database to store the users and their data (e.g. previous orders in an online shop),
1. registration of a domain for the website and an SSL certificate to allow for the encrypted traffic,
1. a DNS setup, so that the domain name gets redirected to the correct servers,
1. a mail server to handle a newsletter and keep mail accounts for the employees or contact the website owner,
1. load balancing, so that a given server doesn't get more traffic than it can handle,
1. a content distribution network: a network of servers placed in different parts of the world, so that the distance to the user (and thus their latency of loading the website) is minimized.

The cloud companies offer all of these and many more, allowing even the most demanding clients to set up their website as they wish, for an appropriate fee. Each company names these products differently: in this article I'll be using the Amazon nomenclature which I used the most.

## Idea behind EC2

The most basic service offered by the cloud providers is shaing a virtual machine, called [Elastic Cloud Compute (EC2)](https://en.wikipedia.org/wiki/Amazon_Elastic_Compute_Cloud) in AWS. It works like any other computer, with dedicated storage, RAM, and CPU, and a operating system, isolated from other users on a given server machine.

When such a VM is accessed with `ssh`, using it doesn't differ much from using a machine owned by the client: they can install programs, start http servers, run compute in the background, etc.

EC2 usage is flexibly billed accordint to the time the machine is on, plus some charges for persistent (non-expiring on shutdown of the VM system) storage.

This type of services allowing low-level control over a server's infrastructure are called Infrastructure-as-a-Service (IaaS).

## Idea behind PaaS

EC2 is very flexible: it allows users to do everything they can imagine with the rented machine[^1]. This flexibility comes with a cost: setting everything up can be a lot of work. If someone wants to have a database, they'll have to install and manage it themselves; same with http server, port forwarding, etc.

[^1]: except for things requiring physically touching it

One particularly painful issue with using EC2 is the problem of scaling: when your website starts to get more requests, you likely want to request more compute resources to spread the additional load. On the other hand, if your EC2 is not being fully utilized, you may want to temporarily shut it down to avoid paying for the compute that you're not using.

Doing this manually is a lot of work, and one of the value propositions behind cloud services is to automate that work.

One answer to the scalability issue is provided through Platform-as-a-Service, with [heroku](https://www.heroku.com/home) and [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/) being popular examples of such services.

Their offer consists of taking care of managing the servers at the level of applications in the operating system: the client is uploading the code, requests whether they need a database, etc. and the platform sets up the actual (virtual) machine, its OS, and takes care of deploying client's code.

Under the hood, it's possible that the lower-level cloud-based services (e.g. EC2, mentioned above) are used to provide the platform's services, but these are hidden to the user.

As the compute infrastructure can be shared across many users of the platform, it is easier to scale the resources: Heroku can request a pool of, say, a thousand EC2, and divide it between its hundreds of users depending on how much resources they need at any given time. Requesting and turning down the actual machines is handled by the platform.

## Idea behind serverless

Another way allowing cloud solutions to offer auto-scaling is through [serverless computing](https://en.wikipedia.org/wiki/Serverless_computing). In that model, the cloud provider pre-allocates some amount of resources and gives the user an ability to execute short requests in already-running applications for a small fee.

The most popular resources shared this way is database and compute.

### Serverless database
For a database, Amazon offers a NoSQL database: [DynamoDB](https://aws.amazon.com/dynamodb/)[^2]. They start thousands of instances of the database on their servers, which are able to handle enormous amounts of traffic. When the user uses the database, they create a table and immediately start to make put/get/query requests through the public (encrypted) network.

The pricing consists mostly of the amount of storage (on the order of $1 per couple of GB-months), and the number of requests to the database (around $1 per a million requests).

[^2]: among many other options

### Serverless compute

[AWS Lambda](https://aws.amazon.com/lambda/) allows users to execute an arbitrary code for a short time. There is a number of ways that the execution of a lambda can be triggered, e.g. via javascript when a user clicks something on a website.

As Amazon keeps a lot of threads waiting for the execution of the code on their servers, the latency for handling a request is much lower compared to starting up an EC2 from scratch. At the same time, as there is no virtual machine which is reserved for a particular user, the costs will be very small if there is little incoming traffic[^3].

[^3]: at the moment of writing, an execution requiring 1GB of memory and taking an hour costs $0.06, and a million requests cost $0.20.

## A couple of examples
Over the last year or two I wrote some web-based applications which I needed to serve somewhere. I used a couple of different methods to see how they work (and how much they cost) in practice.

### Time Stories

The website to play Time Stories (which I described [here](https://sygi.ml/posts/2020-06-19-time-stories.html)) was initially served from an EC2. Whenever friends wanted to play, I needed to start a server, which was a bit annoying, as it was taking ~10min.

Apart from that, even if we didn't play, there were storage costs for the VM's filesystem. While these were free for the first year (due to [AWS Free Tier](https://aws.amazon.com/free/)), I estimate the storage would costs around $2/month for 20GB I needed for the system and the website. This doesn't include game assets which are stored in (cheaper) [Simple Storage Service](https://aws.amazon.com/s3/).

When the free tier ended, I decided to migrate the website to heroku and [MongoDB Atlas](https://www.mongodb.com/atlas/database), which is a provider of serverless MongoDB databases. Both of them have a forever free tier, which was enough to cover my modest usage.

The two problems I encountered with Heroku were: 1) that it doesn't support encrypted traffic (ie. https) in the free tier, and 2) that starting the service was problematic without installing [heroku cli](https://devcenter.heroku.com/articles/heroku-cli) which I didn't want to do on a work laptop.

### 7th continent

After Time Stories, I wrote an app to play 7th continent through a browser. The code for the app evolved from a more general project of an [angular](https://angular.io/) framework for handling cards in a board game.

As it was not initially planned for the use with a particular board game, and I didn't have a lot of energy to write the server-side parts specific for a new game, I decided to go for the serverless solution.

Instead of having a centralized database which would store the state of the game, each client connects to a websocket exposed from [Amazon API Gateway](https://aws.amazon.com/api-gateway/). There, it is connected with a small lambda, which relays messages sent from any client to all the other ones.

As the lambda doesn't store any state, it cannot remember which other clients are connected to the websocket. I store this information in a very small DynamoDB.

In practice, whenever any client moves a card, the website sends the move[^4] through the websocket to all the other clients. Occasionally, multiple players making moves at the same time can cause synchronization problems, but overall, this solution was playable and very quick to implement.

[^4]: or the whole new state? I don't remember anymore.

The only price to pay here is the execution cost for lambdas (dynamodb usage is well within Amazon's always free tier). As a single lambda executes for around 500ms, and uses the lowest possible memory band of 128MB, a million executions (corresponding to a million card moves, and thousands of hours of gameplay) costs around $1.25.

![Screenshot from the website with the game set up. As it is played on an infinite grid, users can increase the grid size using the arrows.](../images/cloud_computing/7th_continent.png){width=70%}

### RSS->email reader

Another project related to serverless computing which I did recently is an RSS to email relayer.

RSS, or [Really Simple Sindication](https://en.wikipedia.org/wiki/RSS) is a web format for announcing updates on a website in a program-readable way. If a website has an RSS feed[^5], there is a page where all (or the recent) content is automatically summarized in an XML.

[^5]: you can see the feed of this blog after clicking the RSS button at the top right.

The users can enter the address of the feed in their RSS reader and updates from all the websites they subscribed to will appear in the reader.

I wanted to get a notification whenever of one the blogs I regularly read[^6] has an update, but I didn't want to install special software and use it every day like it was 2010. Instead, I wanted the updates to show as an email, which I read regularly.

[^6]: most notably, [ciechanow.ski](https://ciechanow.ski) with interactive explanations of stuff

To do this, I set up a lambda to trigger every day, read a list of websites from a dynamodb, and send an email if there was any change to the RSS feed. 

![List of the entries in the RSS database.](../images/cloud_computing/dynamodb.png){width=70%}

The RSS parsing was done using a python library [feedparser](https://feedparser.readthedocs.io/en/latest/), which could be easily deployed as a `zip` archive to the lambda, together with some custom code and other dependencies that I used.

To reduce the bandwidth (and labmda compute time), the library allows to use [If-Modified-Since](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since) HTTP request header. When sent together with the HTTP request, it tells the server to send the full response only if it changed since last time we asked for it. As the lambda doesn't have storage, the time of last request is stored in the database.

For sending the emails, I used Amazon's [SNS](https://aws.amazon.com/sns/) service. It only allows to send emails to addresses that I control (i.e. my addresses) without verification, to avoid people using it to send spam, but that worked fine for me.

## Last words
When making a big, commercial product, it may make sense to hire a network administrator or a DevOps, rent a server room, and manage the hardware on one's own. It allows the most control over the servers and is likely the cheapest option over the long-term.

For very simple web-based services that I am playing with as weekend projects, it doesn't make sense to spend much (any) money on the hardware and time on setting it up. Cloud-based services, in particular serverless compute, allow one to quickly deploy such small, personal projects on the web with a negligible cost, thanks to the economy of scale through sharing hardware resources with thousands of other users.
