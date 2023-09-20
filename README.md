# OCI Object Storage Refresh Data Replication

This Bash script is designed to facilitate the replication of data from one OCI region to another. The typical use case is when you enable an OCI replication policy, but data already exist in the bucket, in this case only newly created data is being replicated to the second region. To address this situation and force OCI to replicate data that existed before enabling the replication policy, this script downloads the existing files locally and then uploads them back, triggering the replication process.

This README.md file provides an explanation of the script's functionality, instructions on how to use it, and details regarding its limitations and constraints.

This script runs :

- within Oracle Cloud Infrastructure (OCI) CloudShell
	- /!\ Disk space is limited to 4GB maximum
- on compute instance with instance_principal authentication
- on compute instance with config_file authentication

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Limitations](#limitations)
- [License](#license)
- [Disclaimer](#disclaimer)
- [Questions](#questions)

---

## Introduction

The OCI OS Refresh Data Replication Script performs the following key actions:

1. Retrieves the OCI Object Storage namespace.
2. Retrieves the approximate size of the specified bucket.
3. Checks the available disk space on the CloudShell file system.
4. Downloads files from the specified bucket to a temporary directory on the CloudShell file system.
5. Controls there is no error during the download process.
6. Uploads files from the temporary directory back to the specified bucket.
7. Controls there is no error during the upload process
8. Displays the total data transferred.
9. Cleans up the temporary directory on the local file system.

## Usage

To use the script, follow these steps:

1. Open an OCI CloudShell session or ssh into a compute instance
2. Download script locally

   ```bash
   curl https://raw.githubusercontent.com/Olygo/OCI-OS_RefreshDataReplication/main/oci_os_rdr.sh -o ./oci_os_rdr.sh && chmod +x ./oci_os_rdr.sh
   ```
3. Run the script from OCI CloudShell with the following command:

   ```bash
   ./oci_os_rdr.sh <bucket_name>
   ```
4. Run the script within a compute instance using config_file authentication:

   ```bash
   ./oci_os_rdr.sh <bucket_name> cf
   ```
5. Run the script within a compute instance using instance_principal authentication:

   ```bash
   ./oci_os_rdr.sh <bucket_name> ip
   ```

   Replace `<bucket_name>` with the name of the OCI Object Storage bucket you want to transfer data to and from.

6. The script will perform the following tasks:
   - Retrieve the OCI Object Storage namespace.
   - Check if the specified bucket exists.
   - Calculate the approximate size of the bucket.
   - Check the available disk space on the local file system (~).
   - Download files from the bucket to a temporary directory (~/<timestamp>_<bucket_name>).
   - Upload files from the temporary directory back to the bucket.
   - Display the total data transferred.
   - Clean up the temporary directory.

## License

This script is provided under the [MIT License](LICENSE). You are free to use, modify, and distribute it as per the terms of the license.


## Disclaimer
**Please test properly on test resources, before using it on production resources to prevent unwanted outages or unwanted bills.**


## Questions ?
Please feel free to reach out for any clarifications or assistance in using this script in your OCI CloudShell environment.

**_olygo.git@gmail.com_**
