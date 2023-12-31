
以前からやりたいと言っていたパラメータ自動評価環境メモ

## 基本:手元で手動実行する編（基本はこちらのみでOK）

##### 概要

```
step1. 事前にclone/環境構築を済ませておいた~/aichallenge2023-racingリポジトリに移動する
step2. AWSIM/autowareをビルドして実行×10回くらい
step3. step2実行時の評価結果を~/aichallenge2023-racing/result.txtに記録する
```

のうち、step1/step2/step3 の部分を作成してみたもの（実体はシェルスクリプト）   

#### 実行方法

前提条件
- README.mdに沿って各種インストール/事前準備完了していること
- autowareのサンプルコードの手動実行が確認できていること

コマンド

```
cd ${HOME}/aichallenge2023-racing
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim-winter/autorun.sh
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim-winter/stop.sh
bash autorun.sh -l 100      #二回目以降はここだけ実行してもOK
```

```
bash autorun.sh           # LOOP回数のdefaultは10回
bash autorun.sh -l 300    # LOOP回数指定したい場合は、option指定すればOK(例えば300回ループしたい場合は "-l 300" のように指定する)
```

結果(`result.txt`)は以下のようになる

```
~/aichallenge2023-sim$ cat result.tsv
Player rawLapTime distanceScore lapTime isLapCompleted isTimeout trackLimitsViolation collisionViolation
20231229123146_automotiveaichallenge_main	248.398743	100	353.398743	true	false	[  3,  6,  4,  1,  0]	[  2,  0,  0,  0]
20231229124031_automotiveaichallenge_main	248.6506	100	363.6506	true	false	[  4,  7,  4,  1,  0]	[  2,  0,  0,  0]
20231229124856_automotiveaichallenge_main	231.108246	47.77975	381.108246	false	false	[  6,  10,  5,  1,  0]	[  2,  0,  0,  0]
20231229125602_automotiveaichallenge_main	128.798477	47.51332	273.798462	false	false	[  5,  8,  5,  2,  0]	[  2,  0,  0,  0]
...
```

`lapTime`が小さくなるようにパラメータ調整やplanner追加など各種工夫に励めばOK

更新方法
```
cd ~/aichallenge2023-sim-racing
cp autorun.sh autorun.sh.20230823
cp stop.sh stop.20230823
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim-winter/autorun.sh
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim-winter/stop.sh
```

## option: サーバ側で自動実行する編（こちらはサーバ側で動作させたい場合のみ使用）

概要

- `github`の該当リポジトリに自動スクリプトからpushできるように設定しておく

```
# (例) seigotさんのリポジトリに更新する場合. YOUR_TOKEN はgithubのsettingメニューから取得しておく.
$ cat ~/.netrc
machine github.com
login seigot
password ${YOUR_PASSWORD/YOUR_TOKEN}
```

関連ツールを事前にインストールしておく

```
sudo apt install -y jq  # result.jsonからの値取得のために必要
```

AWSIMは事前ダウンロードして`${HOME}`においておく
今回はplannerを追加することが多いことを想定し、評価前に`aichallemge2023^racing`リポジトリを新しくcloneするスクリプトにしている

```
ks ${HONE}/AWSIM
```

コマンド

```
cd ${HOME}
git clone https://github.com/seigot/aichallenge-tools
cd aichallenge-tools/aichallenge2023-sim-winter
bash do.sh  # 最新のパッチを取得してautorun_server.sh を何度も実行するスクリプト
```

最新のパッチは以下から取得  
https://github.com/seigot/aichallenge-tools/tree/main/aichallenge2023-sim-winter/patch  
結果は以下に格納  
https://github.com/seigot/aichallenge-result/tree/main/aichallenge2023-sim-winter  

```
# パッチの当て方
cd ~/aichallenge2023-sim
git pull
git diff > tmp.patch               ＃現在の差分を保存
patch -p1 -R < tmp.patch     # 差分を打ち消し
curl  https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/patch/20230824_001_stop_drivable_area_false_left_bound_offset_-0.17_right_-0.67.patch
patch -p1 < 20230824_001_stop_drivable_area_false_left_boundoffset-0.17right-0.67.patch  # 例えばこのパッチを当てる
```

#### planner(ex.[crank_drive_planner](https://github.com/bushio/crank_driving_planner))を追加する場合
既存ファイルの変更のみだと通常の`diff`コマンドでパッチ出力可能だが、ファイル追加する場合はパッチへ出力するために`git add -N`が必要となる  

ex.`crank_drive_planner`のパッチの当て方

```
cd ~/aichallenge2023-sim
git pull
git diff > tmp.patch               ＃現在の差分を保存
patch -p1 -R < tmp.patch     # 差分を打ち消し
# crank planner削除
rm -rf ${HOME}/aichallenge2023-sim/docker/aichallenge/aichallenge_ws/src/aichallenge_submit/crank_driving_planner
# patch当て
curl https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/patch/20230828_with_crank_drive_planner.patch
 -O 20230828_with_crank_drive_planner.patch
patch -p1 < 20230828_with_crank_drive_planner.patch
```

`crank_drive_planner`のパッチの取得方法

```
## ex)
cd ~/aichallenge2023-sim/docker/aichallenge/aichallenge_ws/src/aichallenge_submit
git clone http://github.com/bushio/crank_driving_planner.git 
cd crank_driving_planner
rm -rf .git
cd ..
git add -N crank_driving_planner # git add -Nでパッチに表示されるようになる
git diff > 20230828_001.patch
```
