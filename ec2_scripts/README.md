# Computation with Amazon Web Services

This is a collection of scripts to help you easily perform distributed computation using Gurobi on Amazon Web Services (AWS). These were adapted from code originally by [Iain Dunning](https://github.com/IainNZ).

## Setting up required software

To get starting, you need to install several pieces of software on your system to interface with AWS:

 * Python version 2.7 should be installed
 * If you do not already have the Python package manager `pip` installed, install it by following the instructions [on the pip website](https://pip.pypa.io/en/latest/installing.html).
 * Install required python packages with `sudo pip install paramiko` and `sudo pip install boto`. The `paramiko` package dependencies `ecdsa` and `pycrypto` should be automatically installed; if they are not follow the additional [paramiko installation instructions](http://www.paramiko.org/installing.html).

## Configuring an Amazon Web Services account

The first step is to set up an Amazon Web Services account:

 * Register for an account at [aws.amazon.com](https://aws.amazon.com) (registration will require credit card information).
 * Log in to the AWS console at [console.aws.amazon.com](https://console.aws.amazon.com).
 * Navigate to "Identity & Access Management"; click "Users" and "Create New Users", creating one new user with "Generate an access key for each user" checked.
 * Click "Show User Security Credentials", which should show a "Access Key ID" value and a "Secret Access Key" value. Use these values to create a file located at `~/.boto` with the following format (filling in the *'s with the value from the user security credentials).
```
[Credentials]
aws_access_key_id = **************
aws_secret_access_key = **************
```
 * From the console, navigate to "Identity & Access Management"; click "Users" and select the new user. Under "Inline Policies", click the text "click here" to add a new inline policy (you may need to click the arrow in the "Inline Policies" heading to display this text). Click "Custom Policy" and "Select", entering any policy name desired and the following policy (which grants the user full access to the account):
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

By default an account is limited to 20 simultaneous EC2 nodes of a given type, though an increase can be requested on the AWS Console by selecting the region e.g. "US East", selecting EC2, and then selecting "Limits" on the navigation pane on the left, requesting a limit increase for the instance type. By default, the computation will be carried out in the `us-east-1` region, although this can be modified by changing `AWS_REGION` in `cloud_setup.py`.

## Getting a Gurobi Cloud license for AWS

You will need a Gurobi Cloud license key in order to run Gurobi on AWS. You can obtain a prepaid license for a specified number of hours by contacting Gurobi licensing (this is free for academic use).

Once you have this license, you should paste it into `GUROBI_LICENSE_KEY.txt`. Do **NOT** commit this file or share it e.g. to Github, as it will let anyone use your Gurobi license.

## Configuring your job details

Prepare the `jobdetails.csv` file. This file is a two-column CSV file, where the first line must contain the headers `instance_type` and `command`. Each subsequent line contains the details for a single job. The value in the first column is the instance type you require for this job, and the value in the second column is the corresponding command-line string to run.

## Launching Computation on EC2

The file `dispatcher.py` is used to start the computation job. This script should be run with the following arguments:

```
$ python dispatcher.py -h
usage: dispatcher.py [-h] [-c] [-d] [-v] [-i EXTRA_INPUT_CODE_PATH]
                     [-o EXTRA_OUTPUT_FILE] [--tag_offset TAG_OFFSET]
                     jobname jobfile install_script code_folder results_file
```

Arguments:

1. `jobname` is the name given to this job for identification purposes (all lowercase letters only).
2. `jobfile` should be the path to the `jobdetails.csv` file you created earlier with the instance types and commands for each job.
3. `-c, --create` is an optional argument which will create the machines and run the installation script. It should only be omitted if the machines are already created and set up.
4. `-d, --dispatch` is an optional argument which will start the computation on the machines once they are setup.
5. `-v, --verbose` is an optional argument which will make the script display information as it runs.
6. `--tag_offset` allows you to specify the starting point for numbering machines. The script uses these numbers to refer to the machines uniquely, and defaults to starting at zero. If you already have machines running, you should set this to a number that is greater than the tag number of all currently running machines.

A call to `dispatcher.py` might look like

```
python dispatcher.py jobname jobinfo/jobdetails.csv --create --dispatch
```

## Downloading results

Once the run is completed, the output files are saved in S3 on Amazon Web Services (which has the job name as the S3 bucket name). To download these results run the following:

```
python get_s3_files.py jobname output_folder
```

where `jobname` is the job name that you specified earlier and `output_folder` is the place to put the files.

## Monitoring and Debugging Cloud Runs

There are two major places where a cloud run can fail: during node setup and during the runs themselves.

### Debugging Node Setup Failures

The first time you launch a run on the cloud, it should fail with a message saying that you need to accept the terms and conditions of the Amazon Machine Image (AMI) that we use on EC2. In this case, simply follow the outputted instructions and re-run.

Otherwise, the most likely error to be encountered is one in which the `dispatcher.py` script outputs `Installation complete on 0 / xx boxes` ad infinitum (where `xx` is the number of machines being run on; there is probably trouble if this message appears at least 100 times). This likely indicates an issue in [INSTALL.sh](INSTALL.sh), the script that performs the main setup tasks on each EC2 instance. To resolve such an issue, debug by logging onto a node and looking at the log output generated by [INSTALL.sh](INSTALL.sh). The first step to log into a node is to identify that node's web address. You can do this by logging into the AWS console, selecting "EC2", selecting "Running Instances", selecting an instance, and reading the value under "Public DNS" (we will call this `DNS` in the command that follows). Then you can log into the instance on the command line with:

```
ssh -i ~/.ssh/<jobname>.pem ubuntu@DNS
```

where `jobname` is the job name you specified earlier. Here, `~/.ssh/<jobname>.pem` is a key that was generated when running `dispatcher.py`. It is created by the `cloud_setup.create_keypair` function to enable access to the EC2 nodes without a password.

Once you have logged onto a node, there will be files containing output from the setup tasks. If these steps failed to produce a file named `GUROBI_VERSION`, then there may be additional files with output from additional setup attempts (numbered 2, 3, ...). From reading this output, you may be able to identify and correct a setup issue. Once you determine the cause of the error, you can terminate all running instances from the AWS console by navigating to "EC2" and "Running Instances", selecting all the instances, right clicking, and selecting "Instance State -> Terminate".

### Monitoring and Debugging After Setup

After the `dispatcher.py` script has finished executing, you can check the number of running processes, as EC2 nodes continue running until they have finished all their assigned work, at which point they terminate. One way to check the status of the EC2 nodes is logging onto the AWS console, selecting "EC2" and "Running Instances". Another way is running python interactively from this folder and then running `import cloud_setup` and then `cloud_setup.print_num_running()`.

If there is no progress, then you can debug the run by logging onto one of the EC2 nodes as described in the previous section of this document. Debug output will be available in files `~/code/screen_output.txt`. Once you are finished debugging, you can terminate all running instances from the AWS console by navigating to "EC2" and "Running Instances", selecting all the instances, right clicking, and selecting "Instance State -> Terminate".


# Specific commands to run for computational testing

Create folders called `output` and `results` in the PajaritoSupplement directory.

Run the commands below from the PajaritoSupplement directory. Wait for each command to complete at the command line before running the next one.

1. `python ec2_scripts/dispatcher.py nnnnxxxx ec2_scripts/jobinfo/xxxx.csv --create --dispatch`
2. `python ec2_scripts/get_s3_files.py nnnnxxxx output/xxxx`
3. `julia results_scripts/process.jl output/xxxx results/xxxx.csv`

Where `nnnn` is your name (you need a unique bucket name that will not conflict with any other bucket name on Amazon S3), and `xxxx` is one of the following:
* `pajaritooptions` - runs Pajarito under various options, with CBC and MOSEK
* `opensource` - runs Pajarito under default options, with CBC and ECOS or CIP, and the Bonmin solvers
* `noncommercial` - runs the non-commercial (SCIP) tests
* `commercial` - runs the commercial (Gurobi and MOSEK MISOCP) tests

Results folders will be downloaded to the `output` folder. Processed results csv files will be saved in the `results` folder.



