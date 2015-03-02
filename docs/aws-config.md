## AWS Setup and Configuration

For image and volume data uploads, neuron-catalog depends on [Amazon
Simple Storage Service](http://aws.amazon.com/s3/) by using [Meteor
Slingshot](https://github.com/CulturalMe/meteor-slingshot). You need
to setup and configure this to run your own instance of
neuron-catalog.

1. Create an AWS user and login to the [AWS Console](https://console.aws.amazon.com/).

2. Create an S3 Bucket.

3. In the bucket permissions, add the following CORS configuration:

```xml
<pre>
    <code>
       <?xml version="1.0" encoding="UTF-8"?>
       <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
           <CORSRule>
               <AllowedOrigin>*</AllowedOrigin>
               <AllowedMethod>PUT</AllowedMethod>
               <AllowedMethod>POST</AllowedMethod>
               <AllowedMethod>GET</AllowedMethod>
               <AllowedMethod>HEAD</AllowedMethod>
               <MaxAgeSeconds>3000</MaxAgeSeconds>
               <AllowedHeader>*</AllowedHeader>
           </CORSRule>
       </CORSConfiguration>
    </code>
</pre>
```

4. Enable static website hosting for this S3 bucket by selecting
`Enable website hosting` in the AWS Console. Also set "Index Document"
to `index.html`.

5. Set the bucket policy to (substitute the name of your bucket for
`your-bucket-name`):

<pre>
   <code>
   {
   	"Version": "2008-10-17",
   	"Statement": [
   		{
   			"Sid": "AllowPublicRead",
   			"Effect": "Allow",
   			"Principal": {
   				"AWS": "*"
   			},
   			"Action": "s3:GetObject",
   			"Resource": "arn:aws:s3:::your-bucket-name/*"
   		}
   	]
   }
   </code>
</pre>

6. In the Identity & Access Management (IAM) configuration, create a
user and group for performing the uploads. Note the Access Key and the
Secret Key - you will need to enter these.

7. Still in IAM, set the group policy to the following (again,
substitute the name of your bucket for `your-bucket-name`):

<pre>
    <code>
       {
         "Version": "2012-10-17",
         "Statement": [
           {
             "Sid": "Stmt1410709913000",
             "Effect": "Allow",
             "Action": [
               "s3:*"
             ],
             "Resource": [
               "arn:aws:s3:::your-bucket-name"
             ]
           },
           {
             "Sid": "Stmt1410710014000",
             "Effect": "Allow",
             "Action": [
               "s3:*"
             ],
             "Resource": [
               "arn:aws:s3:::your-bucket-name/*"
             ]
           }
         ]
       }
    </code>
</pre>

8. Now, you need to tell neuron-catalog what your IAM Access Key and
Secret Key created above. These go in a JSON file like the prototype
in `server/server-config.json.example`. Change the relevant variables
and save it as something like `server/server-config.json`. You can
also enter these values into the top of the `Vagrantfile` and
re-create your vagrant machine.