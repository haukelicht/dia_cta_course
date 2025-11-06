from pathlib import Path
import pandas as pd
from sklearn.model_selection import train_test_split

fp = Path("fornaciari_we_2021-pledge_binary.tsv")
if not fp.exists():
    # download the data if not present yet
    url = "https://cta-text-datasets.s3.eu-central-1.amazonaws.com/labeled/fornaciari_we_2021/fornaciari_we_2021-pledge_binary.tsv"
    df = pd.read_csv(url, sep="\t")
    fp.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(fp, sep="\t", index=False)

df = pd.read_csv(fp, sep="\t")

id2label = {0: "no pledge", 1: "pledge"}
label2id = {"no pledge": 0, "pledge": 1}

df['label'] = df['label'].map(id2label)

#### Data splitting


df_test = df[df['metadata__split']=='dev']

df_train = df[df['metadata__split']=='trn']
df_train, df_val = train_test_split(df_train, test_size=0.1, stratify=df_train['label'], random_state=42)

# write splits to splits/ as CSV files
split_dir = fp.parent / "splits"
split_dir.mkdir(parents=True, exist_ok=True)

df_train.to_csv(split_dir / "train.csv", index=False)
df_val.to_csv(split_dir / "val.csv", index=False)
df_test.to_csv(split_dir / "test.csv", index=False)
