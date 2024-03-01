# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "application_url" {
  value       = module.alb.dns_alb
  description = "Copy this value in your browser in order to access the deployed app"
}

output "swagger_endpoint" {
  value       = "${module.alb.dns_alb}/api/docs"
  description = "Copy this value in your browser in order to access the swagger documentation"
}
