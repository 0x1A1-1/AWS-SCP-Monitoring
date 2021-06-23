# AWS-SCP-Monitoring
Terraform template for deploying SCP monitoring

## Resources created
- SNS topic that notifies certain DL
- CloudWatch Rule that monitors the following CloudTrail event from SCP:
  - UpdatePolicy
  - CreatePolicy
  - DeletePolicy
  - DetachPolicy
  - DisablePolicyType
  - EnablePolicyType
  - AttachPolicy
- CloudTrail single event filtering and templating


##  How to run

1. Be sure Terraform is installed on your machine.
    1. Execute the command below in a terminal to validate if terraform is installed.
        ```
         terraform --version
        ```
2. Obtain AWS STS credential or use default AWS profile:
    ```
    aws assume-role ROLE_ARN ROLE_SESSION_NAME
    ```
3. Execute the command to initialize terraform:
    ```
    terraform init
    ```
4. Update the email address in `variables.tf` and confirm provision plan (*):
    ```
    vim variables.tf
    terraform plan

    ```
5. Execute the command to launch the provision plan (*):
    ```
    terraform apply
    ```
6. Verify the components were provisioned.
7. Head over to the email targeted by SNS, and `Confirm subscription` before the notification is activated
