
以前からやりたいと言っていたパラメータ自動評価環境メモ

## 基本:手元で手動実行する編（基本はこちらのみでOK）

##### 概要

```
step1. 事前にclone/環境構築を済ませておいた~/aichallenge2023リポジトリに移動する
step2. AWSIM/autowareをビルドして実行×10回くらい
step3. step2実行時の評価結果を~/aichallenge2023/result.txtに記録する
```

のうち、step1/step2/step3 の部分を作成してみたもの（実体はシェルスクリプト）   
よかったら実行してみて下さいー、これで数十回の連続実行が楽になるはずです。

リポジトリURL  
https://github.com/seigot/tools/tree/master/aichallenge_2023

```
autorun.sh
stop.sh
```

#### 実行方法

前提条件
- README.mdに沿って事前準備完了していること
- 各種インストールが完了していること
- 地図データ(pcd,osm)のコピーが完了していること
- autowareのサンプルコードの手動実行が確認できていること

コマンド

```
cd ${HOME}/aichallenge2023-sim
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/autorun.sh
wget https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/stop.sh
bash autorun.sh -l 100      #二回目以降はここだけ実行してもOK
```

```
bash autorun.sh           # LOOP回数のdefaultは10回
bash autorun.sh -l 300    # LOOP回数指定したい場合は、option指定すればOK(例えば300回ループしたい場合は "-l 300" のように指定する)
```

結果(`result.json`)は以下のようになる

```
~/aichallenge2023-sim$ cat result.json 
Time	rawDistanceSocre	distanceScore	task3Duration	isOutsideLane	isTimeout	hasCollided	hasExceededSpeedLimit	hasFinishedTask1	hasFinishedTask2	hasFinishedTask3
20230806101014_seigot_main	33.3776	31.7087	3.20045	false	false	true	false	false	true	false
20230806101355_seigot_main	33.5419	31.8648	3.19995	false	false	true	false	false	true	false
20230806101737_seigot_main	33.4703	31.7968	3.19987	false	false	true	false	false	true	false
20230806102119_seigot_main	33.5021	31.827	3.19994	false	false	true	false	false	true	false
20230806102500_seigot_main	33.5126	31.837	3.1991	false	false	true	false	false	true	false
20230806102842_seigot_main	33.3896	31.7201	3.20017	false	false	true	false	false	true	false
20230806103224_seigot_main	33.4781	31.8042	3.19981	false	false	true	false	false	true	false
20230806103605_seigot_main	33.5385	31.8616	3.19992	false	false	true	false	false	true	false
20230806103947_seigot_main	33.5385	31.8616	3.19992	false	false	true	false	false	true	false
20230806104329_seigot_main	33.5927	31.9131	3.39991	false	false	true	false	false	true	false
...
```

`distanceScore`が伸びるようにパラメータ調整や各種工夫に励めばOK

更新方法
```
cd ~/aichallenge2023-sim
cp autorun.sh autorun.sh.20230823
curl https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/autorun.sh -O autorun.sh
cp stop.sh stop.20230823
curl https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/stop.sh -O stop.sh
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

コマンド

```
cd ${HOME}
git clone https://github.com/seigot/aichallenge-tools
cd aichallenge-tools/aichallenge2023-sim
bash do.sh  # 最新のパッチを取得してautorun_server.sh を何度も実行するスクリプト
```

最新のパッチは以下から取得  
https://github.com/seigot/aichallenge-tools/tree/main/aichallenge2023-sim/patch  
結果は以下に格納  
https://github.com/seigot/aichallenge-result  

```
# パッチの当て方
cd ~/aichallenge2023-sim
git pull
git diff > tmp.patch               ＃現在の差分を保存
patch -p1 -R < tmp.patch     # 差分を打ち消し
curl  https://raw.githubusercontent.com/seigot/aichallenge-tools/main/aichallenge2023-sim/patch/20230824_001_stop_drivable_area_false_left_bound_offset_-0.17_right_-0.67.patch
patch -p1 < 20230824_001_stop_drivable_area_false_left_boundoffset-0.17right-0.67.patch  # 例えばこのパッチを当てる
```

#### [crank_drive_planner](https://github.com/bushio/crank_driving_planner)を使う場合

`crank_drive_planner`のパッチの当て方

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
