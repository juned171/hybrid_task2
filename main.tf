
provider "aws" {
  
  region  = "ap-south-1"
}


//creating security groups
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-15968b7d"   
 ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
}
 ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls1"
  }
}



//
//instance

resource "aws_instance" "web" {
depends_on = [
	      aws_security_group.allow_tls
		]

//
//ami-0447a12f28fddb066
  ami           = "ami-052c08d70def0ac62"
  instance_type = "t2.micro"
  key_name = "mykey11"
  security_groups = [ "allow_tls" ]
  tags={ 
Name = "webos2"
}
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/juned/Downloads/mykey11.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  

}

//




//
//s3
resource "aws_s3_bucket" "webucket" {
  bucket = "webucket1234"
  force_destroy = true
  acl    = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::webucket1234/*"
    }
  ]
}
POLICY
 }
resource "aws_s3_bucket_object" "object" {
  bucket = "webucket1234"
  key    = "cloud.png"
  source = "C:/Users/juned/Pictures/Screenshots/cloud.png"
  etag = "C:/Users/juned/Pictures/Screenshots/cloud.png"
depends_on = [aws_s3_bucket.webucket,
		]
}


//aws efs 
resource "aws_efs_file_system" "efs-example" {
   creation_token = "efs-example"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "EfsExample"
   }
 }


// efs.tf (continued)
resource "aws_efs_mount_target" "efs_mount" {
   file_system_id  = "${aws_efs_file_system.efs-example.id}"
   subnet_id = "${aws_instance.web.subnet_id}"
   security_groups = ["${aws_security_group.allow_tls.id}"]
 }











resource "null_resource" "null-remote-1"  {
 depends_on = [ 
               aws_efs_mount_target.efs_mount,
                  ]
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/juned/Downloads/mykey11.pem")
    host     = aws_instance.web.public_ip
  }
provisioner "remote-exec" {
    inline = [
      
      "sudo mount  ${aws_efs_file_system.efs-example.dns_name}:/  /var/www/html",
      "sudo git clone https://github.com/juned171/hybrid_cloud.git /var/www/html/"
    ]
  }
}













//cloudfront
locals {
  s3_origin_id = "myS3Origin"
}
   resource "aws_cloudfront_distribution" "hybridcld" {
   origin {
         domain_name = "${aws_s3_bucket.webucket.bucket_regional_domain_name}"
         origin_id   = "${local.s3_origin_id}"
  
 custom_origin_config {

         http_port = 80
         https_port = 80
         origin_protocol_policy = "match-viewer"
         origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
      }
         enabled = true
default_cache_behavior {
        
         allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
         cached_methods   = ["GET", "HEAD"]
         target_origin_id = "${local.s3_origin_id}"

 forwarded_values {

       query_string = false
       
 cookies {
          forward = "none"
         }
    }
          
          viewer_protocol_policy = "allow-all"
          min_ttl                = 0
          default_ttl            = 3600
          max_ttl                = 86400

}
  restrictions {
         geo_restriction {
           restriction_type = "none"
          }
     }
 viewer_certificate {
       cloudfront_default_certificate = true
       }
}



//


resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web.public_ip} > publicip.txt"
  	}
}






resource "null_resource" "nulllocal1"  {


depends_on = [
    null_resource.null-remote-1, 
  ]

	provisioner "local-exec" {
	    command = "start  chrome  ${aws_instance.web.public_ip}"
  	}
}
