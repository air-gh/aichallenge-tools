#!/bin/bash -x

#
# サンプルコード(run.sh)を自動実行するためのスクリプト
# README記載のサンプルコード実行手順をスクリプトで一撃でできるようにしてるだけ
#
# 以下を実行すれば動く想定
#   cd ${HOME}/aichallenge2023-sim
#   wget https://raw.githubusercontent.com/seigot/tools/master/aichallenge_2023/autorun.sh
#   wget https://raw.githubusercontent.com/seigot/tools/master/aichallenge_2023/stop.sh
#   bash autorun.sh  # 2回目以降はここだけ実行
#
# 以下を前提としている
# - ${HOME}/aichallenge2023-simが存在していること
# - README.mdに沿って事前準備完了していること
#   - 各種インストールが完了していること
#   - 地図データ(pcd,osm)のコピーが完了していること
#   - autowareのサンプルコードの手動実行が確認できていること

LOOP_TIMES=7 #10
SLEEP_SEC=360 #180
TARGET_PATCH_NAME="default"
CURRENT_DIRECTORY_PATH=`pwd`

# check
AICHALLENGE2023_DEV_REPOSITORY="${HOME}/aichallenge2023-sim"
if [ ! -d ${AICHALLENGE2023_DEV_REPOSITORY} ]; then
   "please clone ~/aichallenge2023-sim on home directory (${AICHALLENGE2023_DEV_REPOSITORY})!!"
   return
fi

function run_awsim(){

    # Pre Process
    # AWSIMを実行する
    # run AWSIM
    AWSIM_ROCKER_NAME="awsim_rocker_container"
    AWSIM_ROCKER_EXEC_COMMAND="cd ~/aichallenge2023-sim/docker; \
    		        rocker --nvidia --x11 --user --net host --privileged --volume aichallenge:/aichallenge --name ${AWSIM_ROCKER_NAME} -- aichallenge-train" # run_container.shの代わりにrockerコマンド直接実行(コンテナに名前をつける必要がある)
    AWSIM_EXEC_COMMAND_ON_BASH="sudo ip link set multicast on lo; \
			source /autoware/install/setup.bash; \
			/aichallenge/AWSIM/AWSIM.x86_64;"
    AWSIM_EXEC_COMMAND="docker exec ${AWSIM_ROCKER_NAME} bash -c '${AWSIM_EXEC_COMMAND_ON_BASH}'"

    # exec awsim
    echo "-- run AWSIM rocker... -->"
    echo "CMD: ${AWSIM_ROCKER_EXEC_COMMAND}"
    gnome-terminal -- bash -c "${AWSIM_ROCKER_EXEC_COMMAND}" &
    sleep 5
    echo "-- run AWSIM... -->"
    echo "CMD: ${AWSIM_EXEC_COMMAND}"
    #gnome-terminal -- bash -c "${AWSIM_EXEC_COMMAND}" &
    #sleep 15
    for ((ii=0; ii<20; ii++));
    do
	gnome-terminal -- bash -c "${AWSIM_EXEC_COMMAND}" &
	sleep 15
	PROCESS_CNT=`ps -aux | grep "${AWSIM_ROCKER_NAME}" | grep AWSIM | wc -l`
	if [ ${PROCESS_CNT} -ge 1 ]; then
            break
	fi
	echo "no process ${AUTOWARE_ROCKER_NAME}, retry.."
    done

    return
}

function run_autoware(){

    # MAIN Process
    # Autowareを実行する
    # run AUTOWARE
    AUTOWARE_ROCKER_NAME="autoware_rocker_container"
    AUTOWARE_ROCKER_EXEC_COMMAND="cd ~/aichallenge2023-sim/docker; \
    		        rocker --nvidia --x11 --user --net host --privileged --volume aichallenge:/aichallenge --name ${AUTOWARE_ROCKER_NAME} -- aichallenge-train" # run_container.shの代わりにrockerコマンド直接実行(コンテナに名前をつける必要がある)
    # bash起動時の環境変数を追加しておく(source /etc/bash.bashrc; source /etc/profile;)
    # rockerはおそらくここにros2用の環境変数を記載している
    AUTOWARE_EXEC_COMMAND_ON_BASH="source /etc/bash.bashrc; source /etc/profile; \
			sudo ip link set multicast on lo; \
			cd /aichallenge; \
			bash build.sh; \
			source aichallenge_ws/install/setup.bash; \
			bash run.sh"
    AUTOWARE_EXEC_COMMAND="docker exec ${AUTOWARE_ROCKER_NAME} bash -c '${AUTOWARE_EXEC_COMMAND_ON_BASH}'"

    echo "-- run AUTOWARE rocker... -->"    
    echo "CMD: ${AUTOWARE_ROCKER_EXEC_COMMAND}"
    gnome-terminal -- bash -c "${AUTOWARE_ROCKER_EXEC_COMMAND}" &
    sleep 5
    echo "-- run AUTOWARE run.sh... -->"
    echo "CMD: ${AUTOWARE_EXEC_COMMAND}"    
    for ((jj=0; jj<20; jj++));
    do
       gnome-terminal -- bash -c "${AUTOWARE_EXEC_COMMAND}" &
       sleep 15
       PROCESS_CNT=`ps -aux | grep "${AUTOWARE_ROCKER_NAME}" | grep "bash run.sh" | wc -l`
       if [ ${PROCESS_CNT} -ge 1 ]; then
           break
       fi
       echo "no process ${AUTOWARE_ROCKER_NAME} AWSIM, retry.."
    done
    sleep 15
}

function get_result(){

    # 起動後何秒くらい待つか(sec)
    WAIT_SEC=$1

    # wait until game finish
    sleep ${WAIT_SEC}

    # POST Process:
    # ここで何か結果を記録したい
    AUTOWARE_ROCKER_NAME="autoware_rocker_container"
    RESULT_TSV="result.tsv" #"${HOME}/result.json"
    RESULT_TMP_JSON="result_tmp.tsv" #"${HOME}/result_tmp.json"
    GET_RESULT_LOOP_TIMES=10
    VAL1="-1" VAL2="-1" VAL3="-1" VAL4="false" VAL5="false"
    VAL6="false" VAL7="false" VAL8="false" VAL9="false" VAL10="false"
    for ((jj=0; jj<${GET_RESULT_LOOP_TIMES}; jj++));
    do
	docker exec ${AUTOWARE_ROCKER_NAME} cat /aichallenge/result.json > ${RESULT_TMP_JSON}
	if [ $? == 0 ]; then
	    # result
	    VAL1=`jq .rawDistanceScore ${RESULT_TMP_JSON}`
	    VAL2=`jq .distanceScore ${RESULT_TMP_JSON}`
	    VAL3=`jq .task3Duration ${RESULT_TMP_JSON}`
	    VAL4=`jq .isOutsideLane ${RESULT_TMP_JSON}`
	    VAL5=`jq .isTimeout ${RESULT_TMP_JSON}`
	    VAL6=`jq .hasCollided ${RESULT_TMP_JSON}`
	    VAL7=`jq .hasExceededSpeedLimit ${RESULT_TMP_JSON}`
	    VAL8=`jq .hasFinishedTask1 ${RESULT_TMP_JSON}`
	    VAL9=`jq .hasFinishedTask2 ${RESULT_TMP_JSON}`
	    VAL10=`jq .hasFinishedTask3 ${RESULT_TMP_JSON}`
	    break
	fi
	# retry..
	sleep 10
    done

    if [ ! -e ${RESULT_TSV} ]; then
	echo -e "Player\trawDistanceSocre\tdistanceScore\ttask3Duration\tisOutsideLane\tisTimeout\thasCollided\thasExceededSpeedLimit\thasFinishedTask1\thasFinishedTask2\thasFinishedTask3" > ${RESULT_TSV}
    fi
    TODAY=`date +"%Y%m%d%I%M%S"`
    OWNER=`git remote -v | grep fetch | cut -d"/" -f4`
    BRANCH=`git branch | cut -d" " -f 2`	    
    echo -e "${TODAY}_${OWNER}_${BRANCH}_${TARGET_PATCH_NAME}\t${VAL1}\t${VAL2}\t${VAL3}\t${VAL4}\t${VAL5}\t${VAL6}\t${VAL7}\t${VAL8}\t${VAL9}\t${VAL10}" >> ${RESULT_TSV}
    echo -e "${TODAY}_${OWNER}_${BRANCH}_${TARGET_PATCH_NAME}\t${VAL1}\t${VAL2}\t${VAL3}\t${VAL4}\t${VAL5}\t${VAL6}\t${VAL7}\t${VAL8}\t${VAL9}\t${VAL10}"

    # finish..
    bash stop.sh

}

function push_result(){
    RESULT_REPOSITORY_URL="https://github.com/seigot/aichallenge-result"
    RESULT_REPOSITORY_PATH="${HOME}/aichallenge-result"
    if [ ! -d ${RESULT_REPOSITORY_PATH} ]; then
	pushd ${HOME}
	git clone ${RESULT_REPOSITORY_URL}
	popd
    fi
    pushd ${RESULT_REPOSITORY_PATH}/aichallenge2023-sim
    git pull
    BEST_TIME=`cat ${CURRENT_DIRECTORY_PATH}/result.tsv | grep ${TARGET_PATCH_NAME} | cut -f2 | sort -n | tail -2 | head -1` # 外れ値を除くために2番目の値を取得(要調整)
    PUSH_RESULT_NAME="result_${TARGET_PATCH_NAME}_${BEST_TIME}.tsv"
    cat ${CURRENT_DIRECTORY_PATH}/result.tsv | head -1 > ${PUSH_RESULT_NAME}
    cat ${CURRENT_DIRECTORY_PATH}/result.tsv | grep ${TARGET_PATCH_NAME} >> ${PUSH_RESULT_NAME}
    git add ${PUSH_RESULT_NAME}
    git commit -m "update result"
    git push
    popd
}

function preparation(){

    # stop current process
    bash stop.sh

    # リポジトリ設定など必要であれば実施（仮）
    echo "do_nothing"
}

function do_game(){
    SLEEP_SEC=$1
    preparation
    #run_awsim
    #run_autoware
    ## 通常AWSIM-->AUTOWAREの起動手順だが、
    ## AUTOWARE-->(2min sleep)-->AWSIMとしないと回避できない(centerpointtopic起きてこない)ので暫定対応
    run_autoware
    sleep 120
    run_awsim
    get_result ${SLEEP_SEC}
}

function update_patch(){

    # target patch名の取得
    # 取得できない場合は-1を返す
    AICHALLENGE2023_TOOLS_REPOSITORY_PATH="${HOME}/aichallenge-tools"
    TARGET_PATCH_LIST="target_patch_list.txt"
    TARGET_PATCH=""
    pushd ${AICHALLENGE2023_TOOLS_REPOSITORY_PATH}"/aichallenge2023-sim/patch"
    for PATCH_NAME in `ls *.patch`
    do
	echo "TARGET_PATCH_CANDIDATE: ${PATCH_NAME}"
	grep -x "${PATCH_NAME}" ${TARGET_PATCH_LIST}
	RET=$?
	if [ ${RET} == 0 ]; then
            echo "PATCH: ${PATCH_NAME} already evaluated..."
            continue
	fi
	TARGET_PATCH="${PATCH_NAME}"
	break
    done
    if [ "${TARGET_PATCH}" == "" ]; then
	echo "no target patch.."
	return 1
    fi
    echo "TARGET_PATCH: ${TARGET_PATCH} evaluation start"
    echo ${TARGET_PATCH} >> ${TARGET_PATCH_LIST}
    TARGET_PATCH_NAME="${TARGET_PATCH}"
    popd

    # patch更新
    ## 前の変更点を削除
    pushd ${AICHALLENGE2023_DEV_REPOSITORY}
    git diff > tmp.patch
    patch -p1 -R < tmp.patch
    # crank planner削除
    rm -rf ${HOME}/aichallenge2023-sim/docker/aichallenge/aichallenge_ws/src/aichallenge_submit/crank_driving_planner
    ## target patch反映
    patch -p1 < ${AICHALLENGE2023_TOOLS_REPOSITORY_PATH}"/aichallenge2023-sim/patch/${TARGET_PATCH_NAME}"
    popd
    return 0
}

# 引数に応じて処理を分岐
# 引数別の処理定義
while getopts "a:l:s:" optKey; do
    case "$optKey" in
	a)
	    echo "-a = ${OPTARG}";
	    run_awsim;
	    ;;
	l)
	    echo "-l = ${OPTARG}"
	    LOOP_TIMES=${OPTARG}
	    ;;
	s)
	    echo "-s = ${OPTARG}"
	    SLEEP_SEC=${OPTARG}
	    ;;
    esac
done

# main loop
echo "LOOP_TIMES: ${LOOP_TIMES}"
echo "SLEEP_SEC: ${SLEEP_SEC}"
update_patch
RET=$?
if [ "${RET}" == "1" ]; then
    echo "NO EVALUATION PATCH, exit..."
    exit 0
fi 
for ((i=0; i<${LOOP_TIMES}; i++));
do
    echo "----- LOOP: ${i} -----"
    do_game ${SLEEP_SEC}
done
push_result
