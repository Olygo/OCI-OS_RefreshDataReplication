#!/bin/bash

config_file="~/.oci/config"

# Expand path
eval config_file="$config_file"

# Check arguments
if [ $# -lt 1 ]; then
    echo
    echo "Missing argument(s)..."
    echo "Usage: $0 bucket_name auth_method"
    echo
    echo "      $0 bucket_name ip | cf"
    echo
    exit 1
fi

# Assign the first argument to bucket_name
bucket_name="$1"

# Check authentication argument
if [ -n "$2" ]; then
    if [ "$2" = "ip" ]; then
        auth="--auth instance_principal"
        echo
        echo "auth_method = Instance principal"
        echo
    elif [ "$2" = "cf" ]; then
        if [[ -f $config_file ]]; then
            auth="--auth api_key"
            echo
            echo "auth_method = Config file"
            echo
        else
            echo " /!\ CONFIG FILE NOT FOUND: $config_file"
            exit 1
        fi
    else
        echo
        echo " /!\ INVALID AUTH ARGUMENT: $2"
        echo
        exit 1
    fi
else
    auth=""
fi

echo
echo "= = = = = = = RETRIEVING NAMESPACE = = = = = = ="
echo

oci_output=$(oci os ns get $auth)

namespace=$(echo "$oci_output" | jq -r '.data')

if [ -z "$namespace" ]; then
   echo
   echo "/!\ UNABLE TO GET NAMESPACE, CHECK AUTHENTICATION METHOD"
   echo
   exit 1
else
   echo " $namespace"
fi

echo
echo "= = = = = = = RETRIEVING BUCKET SIZE = = = = = = ="
echo

get_bucket_size=$(oci os bucket get -bn $bucket_name -ns $namespace --fields 'approximateSize' $auth)

# Check if ServiceError while getting bucket size => usually because bucket does't exist
if echo "$get_bucket_size" | jq -e 'contains("ServiceError")' > /dev/null 2>&1; then
    # oci will display the detailed error here
    echo
    echo "Or maybe the bucket is located in another region ?"
    echo
    exit 1
else
    # Retrieve approximate-size from json (Bytes)
    bucket_size=$(echo "$get_bucket_size" | jq -r '.data."approximate-size"')

    # Convert integer to float with 2 decimal places & bucket_size from Bytes to Gigabytes
    bucket_size_gb=$(awk "BEGIN {printf \"%.2f\", $bucket_size/1024/1024/1024}")
    bucket_size_kb=$(awk "BEGIN {printf \"%.2f\", $bucket_size/1024}")
    
    echo " Bucket "$bucket_name" approximate size is: $bucket_size_gb"GB
    
    echo
    echo "= = = = = = = CHECK LOCAL DISK FREE SPACE in ~ (/home/username) = = = = = = ="
    echo
    available_space_kb=$(df -BK ~ | awk 'NR==2 {print $4}' | sed 's/K//')
    available_space_gb=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')

    # Check if local_disk_space >= $bucket_size_gb

    # Convert available_space_kb and bucket_size_kb to integers
    available_space_int=${available_space_kb%.*} # Remove decimal point
    bucket_size_int=${bucket_size_kb%.*} # Remove decimal point

    if [ "$available_space_int" -ge "$bucket_size_int" ]; then
        echo "Local disk space ok -  Local: $available_space_int / bucket_size: $bucket_size_int"
    else
        echo
        echo " /!\ NOT ENOUGH DISK SPACE -  Local: $available_space_kb / bucket_size: $bucket_size_kb"
        echo
        exit 1
    fi

    tmp_dir=$(date +%d%m%y%H%M%S)_$bucket_name
    mkdir ~/$tmp_dir

    echo
    echo "= = = = = = = DOWNLOADING FILES IN PROGRESS = = = = = = ="
    echo
    download_output=$(oci os object bulk-download -bn $bucket_name --dest-dir ~/$tmp_dir -ns $namespace $auth)

    # Check if download_failures is empty or not
    if [ "$(echo "$download_output" | jq '.["download-failures"] | length > 0')" = true ]; then

        echo
        echo "$download_output" | jq -r '.["download-failures"]'
        echo
        echo " /!\ download_failures found please check :"
        echo "                                        - error above"
        echo "                                        - local disk space"
        echo "                                        - real bucket size"
        echo
        echo "= = = = = = = CLEANING LOCAL FILES = = = = = = ="
        echo
        rm -rdf ~/$tmp_dir
        echo " Local files deleted..."
        echo
        exit 1
    else
        echo
        #echo $download_output
        echo
        echo "No download_failures found, continuing"
        echo
    fi

    echo
    echo "= = = = = = = UPLOADING FILES IN PROGRESS = = = = = = ="
    upload_output=$(oci os object bulk-upload -bn $bucket_name --src-dir ~/$tmp_dir -ns $namespace --overwrite --verify-checksum $auth)

    # Check if upload_failures is empty or not
    if [ "$(echo "$upload_output" | jq '.["upload-failures"] | length > 0')" = true ]; then

        echo
        echo "$upload_output" | jq -r '.["upload-failures"]'
        echo
        echo " /!\ upload_failures found please check :"
        echo "                                        - error above"
        echo "                                        - local disk space"
        echo "                                        - real bucket size"
        echo
        echo " /!\ Local temporary data  kept in: ~/$tmp_dir"
        echo " /!\ fix the issue, then manually run upload command "
        echo
        echo "oci os object bulk-upload -bn BUCKET_NAME --src-dir ~/$tmp_dir -ns NAMESPACE --overwrite --verify-checksum"
        exit 1
    else
        echo
        #echo $upload_output
        echo
        echo "No upload_failures found, continuing"
        echo
        echo "= = = = = = = TOTAL DATA TRANSFERED = = = = = = ="
        echo
        du -h -d1 ~/$tmp_dir

        echo
        echo "= = = = = = = CLEANING LOCAL FILES = = = = = = ="
        echo
        rm -rdf ~/$tmp_dir
        echo " Local files deleted..."
        echo
    fi
fi