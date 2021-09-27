#!/bin/bash

USER=CHANGE_ME
NODE_IP=CHANGE_ME

if [ $NODE_IP = "CHANGE_ME" ]; then
    echo "Remote user with sudo access:"
    read USER
    echo "Remote IP address:"
    read NODE_IP

    sed -i "0,/USER=CHANGE_ME/s//USER=$USER/" $0
    sed -i "0,/NODE_IP=CHANGE_ME/s//NODE_IP=$NODE_IP/" $0
fi

if ssh -q $USER@$NODE_IP exit; then
    echo "Connected to the node successfully"
else
    echo "Failed to connect to node"
    exit
fi


PS3='Please enter your choice: '
options=("Restart Validator" "Rotate Keys" "Validator Status" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Restart Validator")
            ssh -tq $USER@$NODE_IP "sudo systemctl restart polkadex.service"; echo "Validator Restarted"
            ;;
        "Rotate Keys")
            echo NEW KEYS: $(ssh -q $USER@$NODE_IP $'curl -sH "Content-Type: application/json" -d \'{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}\' http://localhost:9933 | grep -oP \'(?<="result":")[^"]*\'')
            ;;
        "Validator Status")
            echo "Validator Status:"; ssh -tq $USER@$NODE_IP "sudo systemctl status polkadex.service"
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
