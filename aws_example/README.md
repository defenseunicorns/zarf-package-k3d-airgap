# LeapfrogAI single node k3d example deployment on AWS GovCloud

## Directory Structure & Explanation

Root directory contains the terraform needed to build the instance on AWS
GovCloud with ssh access and a public IP address. To update the configuration
for additional testing, the user should just have to update the variables.tf
file with the appropriate values.

The scripts directory contains the needed files to configure the EC2 instance
and then run the experimental deployment.

The bbkill.sh script is used to tear down a deployment of DUBBD or Big Bang
should zarf remove not work as expected.

The ec2_prep_final.sh script is an idempotent script that will install the
required dependencies for k3d, Dubbd, Metallb, and LeapfrogAI to prepare the
instance for deployment via zarf packages. For actual airgapped systems, this
is being provided as an example of what a RHEL 9 or similar system needs prior
to executing the deployment. Additional information is outlined in the script
documentation itself.

The example_instructions.sh script demonstrates the order of operations needed
to generate a functional LeapfrogAI deployment. The user will be required to
update variables and values as needed for their specific deployment and
generate their own key pair prior to executing any of the example to include
the terraform.
