# Introduction
This is a basic collection of files intended to support an introductory discussion about Infrastructure as Code and Observability/Monitoring.

It is simple but hopefully fairly well commented, the goal being that people can follow along to either deploy directly into an AWS account, or at least get a sense of how something could be started.

### It is...
- intended to engender curiosity around the subject
- basic and simple
- [hopefully] easy to follow

### It is not...
- robust or comprehensive
- an example of the finest code or configuration
- definitive, the reader is fully expected to explore further! :ok_hand:

# Setup
I'm using a Mac, so the commands and configuration are for that... I would imagine a Linux or Windows config would be very similar.

## Terraform
[Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli "Terraform installation") for your platform, I'm using Homebrew, so `brew install terraform` which gave me version `0.14.5`. 

## Editor
I'm using [Visual Studio Code](https://code.visualstudio.com/Download "VS Code") with a few extensions:
 - [HashiCorp Terraform](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform "Id: hashicorp.terraform") published by HashiCorp. This extension marks up the Terraform files making in-page navigation easy, and it also provides code completion, descriptions on hover and some other features
 - [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python "Id: ms-python.python") published by Microsoft
   
## AWS Configuration
It is assumed that you already have an AWS account and have the ability to invoke the command line using the AWS [shared credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html "AWS Shared Credentials File"). In addition to the credentials, I also set the config file and use a profile.

The [AWS CLI (v2)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html "AWS CLI v2") is installed too, but isn't required for this to work - however, it's very useful to prove programmatic connectivity from the client into AWS with parameters like `--profile`, an example if there are problems with access could be:
```bash
export PROFILE=my_profile_name
aws iam get-user --profile ${PROFILE} --debug
```
far easier than trying to determine why programmatic access isn't working via Terraform!

## Internet
It should be noted that Internet access is needed for this all to work, not only for AWS access, but the `terraform` commands will retrieve plugins (`archive`, `aws` etc.).

## Missing Configuration
There is a file called `terraform.tfvars` that's not committed to the repo, largely because it contains an AWS account number. Alongside the files `main.tf` and `aws.tf` in the [`Terraform`](./Terraform/ "Terraform") root, create the file `terraform.tfvars` and add the following, noting that the values in curly braces need to be replaced:
```hcl
#
# Externalise all the variables from the configuration
#
aws_profile   = "{PROFILE_NAME}"

#
# Override the variable defaults
#
function_name  = "Embedded-Metrics-Tinkering"
function_alias = "alias"
publish        = true

#
# The AWS account number of the account where the function will be deployed into
#
target_account = {AWS_ACCOUNT_NUMBER}
```

## Files
Whilst there are a few other files (like supporting [Material](./Material/ "Material")) the files below are the salient ones:
```text
├── Function
│   └── lambda_function.py
├── LICENCE.md
├── README.md
└── Terraform
    ├── State
    │   └── terraform.tfstate
    ├── aws.tf
    ├── main.tf
    ├── modules
    │   └── log_group
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars
    └── variables.tf
```

The `lambda_function.py` is a Python file that will be deployed by the Terraform contained in the `*.tf*` files. This is the README and the LICENCE is provided for the avoidance of doubt about what can be done with this repo.

The Terraform files are the ones ending `.tf` and the structure is that the `Terraform` directory is the [root](https://www.terraform.io/docs/language/files/index.html "root"), with modules contained in the `modules` subdirectory. A larger implementation would probably have a far more complex structure, maybe with different environments for a route-to-live or a range of modules. The modules here are referenced off the local file system such as `source = "./modules/log_group"` but could equally be other git repositories etc.

Terraform parses all the `.tf` and `.tfvars` files in each directory. The filenames aren't critical, but a convention is the `main.tf`, `variables.tf` & `outputs.tf` with others being named for common sense.

The `State` directory is where Terraform will hold what it calls the [`backend`](https://www.terraform.io/docs/language/settings/backends/index.html "Backends") which in this case is simply local (as in, a file on the local file system) but more likely would be to store the state in an [S3 bucket](https://www.terraform.io/docs/language/settings/backends/s3.html "S3 Backend").

The `terraform.tfvars` file is one of the ways that variable assignment can be done, see [here](https://www.terraform.io/docs/language/values/variables.html#assigning-values-to-root-module-variables "assigning variables") for more details.

# Deployment into AWS
The following assumes the files are all cloned or downloaded to a local directory and that the user is familiar with a command line, the following may need to be tweaked depending on your OS, something like:
```bash
git clone https://github.com/rswift/lobular-doodle.git
cd lobular-doodle/Terraform
touch terraform.tfvars
```
Now edit the `terraform.tfvars` file in line with the [Missing Configuration](#missing-configuration "Missing Configuration") above.

The first thing to do with Terraform is to [initalise](https://www.terraform.io/docs/commands/init.html "terraform init") the Terraform configuration:
```bash
terraform init
```
which downloads required files and initialises the directory for Terraform. If you make changes to the Terraform, such as adding a module, it'll be necessary to rerun the `terraform init` commmand.

The next step is to evaluate what changes are required to your AWS account:
```bash
terraform plan
```
assuming this is the first time this has been run, the command above will parse all the files and show all the resources that'll be created. Towards the end of the output the number of resources added, changed or destroyed will be listed, along with what outputs will be returned when the resources are created in AWS.

Note that no new resources have been created in AWS yet... To do so:
```bash
terraform apply
```
which will take a moment or two, it'll show something very similar to the `plan` from above but this time you'll be prompted to perform the actions, so answer `yes` to the question (the command line option `-auto-approve` can be added to the `apply` to automatially answer that question positively) and when the resources have been added, you'll see the outputs which should include the full ARN of the function, the policy etc.

At this point, you can navigate to the [Lambda Console](https://console.aws.amazon.com/lambda/home?#/functions "Lambda Console") in the AWS account and inspect the newly minted function. To invoke, you can simply create a [test event](https://docs.aws.amazon.com/lambda/latest/dg/getting-started-create-function.html#get-started-invoke-manually "Lambda Test Event") that can be anything, the default Hello World entry is fine, the data isn't used by this function.

## AWS Resources
The Terraform created:
- a CloudWatch Log Group
  - this is implemented from Terraform via a module, see [Terraform/modules/log_group/main.tf](/Terraform/modules/log_group/main.tf "module main.tf") to start with
  - this is done because there is no other way (at least not today?) to set the retention period for automatically created Lambda Log Groups
- a Lambda function
  - [Function/lambda_function.py](./Function/lambda_function.py "code") is the code
  - the Terraform configuration to create the function itself is in [Terraform/main.tf](./Terraform/main.tf#L11 "main.tf"), in the entry on line 11 `resource.aws_lambda_function.terraform_lambda`
- a Lambda alias
  - see `aws_lambda_alias.terraform_lambda_alias` and although this isn't used, it was added as a demonstration of the dependencies between resources inside the Terraform configurations
- IAM policy (to permit CloudWatch etc.) and role for the Lambda
  - see `resource.aws_iam_policy.lambda_policy` & `resource.aws_iam_role.lambda_role`
  - the policy is then attached to the role

## How does Terraform interact
In this example, I'm using two separate AWS accounts to demonstrate that Terraform can assume a role in account 2, from account 1. This is a likely scenario in most AWS account configurations as it makes a lot of sense to separate concerns and most AWS estates comprise multiple accounts.

The `terraform` commands get their AWS credentials via the [`aws.tf`](./Terraform/aws.tf#L34 "aws.tf") file, see the `provider` section on line 34 which specifies the role that Terraform will assume. Obviously this needs the correct IAM configuration in both accounts.

Most likely there will be an account paving process to configure the various accounts, that's somewhat involved for what I'm trying to show here, so for simplicity...

### Target Account: 1
Purpose: Providing centralised credentials for critical remote access (in this case Terraform) in order to permit that trusted tool to assume a role in the target account (Account 2). Centralised access means one place to enable, monitor and deny access etc.

IAM requirement: IAM user with API & Secret Key to enable API access into AWS, configured on the client against a given `profile`. There are possibly other ways to solve this access problem.

### Target Account: 2
Purpose: To host the Lambda, CloudWatch Logs and other resources
IAM requirement: A role (called `deploy` in this example) that can be assumed from Account 1, with appropriate policies to allow the required resources to be created by Terraform - which in turn will create new resources that will provide the new capability.

The policies needed by Terraform to achieve this are included in the [Material/Account 2 IAM](./Material/Account%202%20IAM/ "policies") directory. Obviously principles of least privilege should apply such that the tooling only has the bare minimum permission to achieve the task. 

I created a separate `console` account for access to the AWS account via a browser.

### But I only have one AWS account!
No problem simply comment out the `assume_role {}` section in [`aws.tf`](./Terraform/aws.tf#L44 "aws.tf"). Note though that regardless of how many accounts, terraform needs the permission to invoke the required APIs, as per the policies described [here](./Material/Account%202%20IAM/deploy-iam.json "IAM"), [here](./Material/Account%202%20IAM/deploy-monitoring.json "monitoring") & [here](./Material/Account%202%20IAM/deploy-compute.json "compute").

### Troubleshooting
If you have problems excuting the terraform, [terraform logging](https://www.terraform.io/docs/internals/debugging.html "terraform debugging") can be enabled:
```bash
echo "the log level can be one of TRACE, DEBUG, INFO, WARN or ERROR" > /dev/null
export TF_LOG=INFO
```
note that `DEBUG` will give quote a lot of output that isn't always additionally helpful over and above `INFO`. To turn off logging, simply:
```bash
unset TF_LOG
```

## Destroy!
The resources can be removed as easily as they were added, simply:
```bash
terraform destroy
```
and they will be removed from the account. Clearly this has its implications, and there are means to prevent inappropriate resource removal, both within AWS such as IAM policy limitations on the Terraform execution, or using the explicit [Terraform lifecycle `prevent_destroy`](https://www.terraform.io/docs/language/meta-arguments/lifecycle.html#prevent_destroy "prevent_destroy") setting. There will almost certainly be a need to have some resources that should never be removed, and others that can be.

## Making Changes
A simple change to demonstrate updating resources would be to alter the Log Group retention period. To do so, comment in line 81 in [main.tf](./Terraform/main.tf#L81 "main.tf") but note that this value must be selected from a list, see documentation from [Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group#retention_in_days "Terraform Resource") or [AWS](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutRetentionPolicy.html#API_PutRetentionPolicy_RequestSyntax "AWS API"). Change the value to something like `7` then simply:
```bash
terraform apply -auto-approve
```
to support this, I added the retention period to the outputs, so the `apply` should show an entry `log_group_retention` with a value of the number of days. If line 81 is commented out, this output will still show, because a default value is set in the [variables.tf](./Terraform/modules/log_group/variables.tf#L14 "variables.tf") file.

# Visualising Resources
It is possible to visualise the relationships between Terraform elements, although even for this somewhat simple example, the image is already getting quite complex!
```
brew install graphviz
terraform graph | dot -Tpng -ovisual.png
```
which should create a PNG, an example can be found here: [visual.png](./Material/visual.png "rendering of AWS resources").

# Lambda
The [Lambda function](./Function/lambda_function.py "source file") was written to show a Python native approach to pushing metrics into CloudWatch via a logging entry.

![Capturing and logging the metrics](./Material/logging%20metrics.png "Capturing & Logging Metrics")

The idea of this is to show the [CloudWatch Embedded Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format.html "CloudWatch Embedded Metrics") feature which is a capability of CloudWatch to extract metrics alongside high cardinality data for handling in CloudWatch alongside all other metrics (i.e. counts of events, durations etc.) but at the same time providing the ability to use CloudWatch Insights (or other log query tooling) to provide a powerful instrumentation capability that doesn't require specific code changes to provide runtime insights into application performance, behaviour, troubleshooting etc.

![Viewing, using and querying logged data](./Material/metrics%20and%20insights.png "Viewing Logged Data")
