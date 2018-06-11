#!/bin/bash

mkdir -p data/local
local=`pwd`/local
scripts=`pwd`/scripts

export PATH=$PATH:`pwd`/../../../tools/irstlm/bin

echo "Preparing train and test data"

train_base_name=train_yesno
test_base_name=test_yesno
waves_dir=$1

# 生成所有音频文件的列表
ls -1 $waves_dir > data/local/waves_all.list

cd data/local

# 将所有音频文件分成训练集和测试集
../../local/create_yesno_waves_test_train.pl waves_all.list waves.test waves.train

# 生成.scp文件，主要内容是音频文件的路径，具体格式如下：
# 0_0_0_0_1_1_1_1 waves_yesno/0_0_0_0_1_1_1_1.wav
../../local/create_yesno_wav_scp.pl ${waves_dir} waves.test > ${test_base_name}_wav.scp
../../local/create_yesno_wav_scp.pl ${waves_dir} waves.train > ${train_base_name}_wav.scp

# 根据音频文件的文件名生成该音频文件的标注
../../local/create_yesno_txt.pl waves.test > ${test_base_name}.txt
../../local/create_yesno_txt.pl waves.train > ${train_base_name}.txt

# 1-gram语言模型
cp ../../input/task.arpabo lm_tg.arpa

cd ../..

# This stage was copied from WSJ example
for x in train_yesno test_yesno; do 
  mkdir -p data/$x
  cp data/local/${x}_wav.scp data/$x/wav.scp
  cp data/local/$x.txt data/$x/text
  # utt2spk中内容类似于：0_0_0_0_1_1_1_1 global
  # 因为utt2spk和spk2utt具有相同的信息 
  # utt2spk 格式 ：
  # <utterance-id> <speaker-id>
  # spk2utt 格式 ：
  # <spaker-id> <utterance-id>…
  cat data/$x/text | awk '{printf("%s global\n", $1);}' > data/$x/utt2spk
  utils/utt2spk_to_spk2utt.pl <data/$x/utt2spk >data/$x/spk2utt
done

