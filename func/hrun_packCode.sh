#!/bin/bash

workdir=$1
JOB_NAME=$2
tag=$3
python_container=$(tail -1 ${workdir}/ini/container.ini | awk -F , '{print $1}')
python_home=$(tail -1 ${workdir}/ini/container.ini | awk -F , '{print $2}')
jenkins_container=$(cat ${workdir}/ini/jenkins.ini | grep "jenkins_container" | awk -F = '{print $2}')

# 将打包shell脚本copy一份到Jenkins工作路径，并打包到python容器
echo "this is hrun_packCode.sh,pwd is：$(pwd)"
jenkins_workspace=$(pwd)
packageName=${JOB_NAME}${tag}
# 注意：此写法默认在jenkins下进行
#       cli执行需要将代码包放置当前目录pwd的上级目录中。
cp ${workdir}/func/cvfTarCode.sh $(dirname $jenkins_workspace)/cvfTarCode.sh
cd $(dirname $jenkins_workspace) && chmod +x cvfTarCode.sh && ./cvfTarCode.sh ${packageName} ${JOB_NAME}

:<<!
docker cp ${workdir}/func/cvfTarCode.sh ${jenkins_container}:/var/jenkins_home/workspace
docker exec ${jenkins_container} sh -c "cd /var/jenkins_home/workspace && chmod +x cvfTarCode.sh && ./cvfTarCode.sh ${packageName} ${JOB_NAME}"
mkdir -vp /root/codepackage
docker cp ${jenkins_container}:/var/jenkins_home/workspace/${packageName}.tar /root/codepackage
docker exec ${jenkins_container} sh -c "cd /var/jenkins_home/workspace && rm -f ${packageName}.tar cvfTarCode.sh"
cd /root/codepackage
!

docker cp ${packageName}.tar ${python_container}:${python_home}
docker cp ${workdir}/func/xvfTarCode.sh ${python_container}:${python_home}
docker exec ${python_container} sh -c "cd ${python_home} && chmod +x xvfTarCode.sh && ./xvfTarCode.sh ${packageName}"

rm -f ${packageName}.tar
