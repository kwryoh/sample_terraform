## 経緯

AWSやAzureなどで、ゲートウェイからインスタンスなどを決まった構成で組めるようにしたい。とか
インスタンスの構築方法自体を変更管理したい、クラウド構築を共有したい、というケースが生じたので
terraformを使ってIaC化しようと思って触ってみました。

## terraform とは

https://www.terraform.io/

Ansible の様に AWS などのクラウド環境をコードで表すことができるツールです。

terraform では EC2のインスタンスやVPCの設定を、"resource {}"という単位で定義されます。
EC2インスタンスを構築する場合、次のようなコードとなります。

```terraform
provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"

  tags = {
    Name = "TFSampleInstance"
  }
}
```

"ami"、"ap-northeast-1"や"t2.micro"など見たことある名称がありますね。
こんな形で割と直感的に、クラウド環境構築を定義でき、コードであるため、Gitで管理かつ共有も可能になります。

terraform からインスタンスの作成をするには次のコマンドを実行します。

```sh
# リソースの作成
$ terraform apply
# リソースの削除
$ terraform destroy
```

## terraform で AWS の EC2 をたてるまで

ここでは下図のような単純な EC2 インスタンスを作ることを目的とします。

![terraform-sample.png](https://rga.qiita.com/files/4a6bf65a-2537-f035-287c-80986e0c2102.png)

### 環境準備

まず terraform をインストールします。Mac の場合は brew を使うと容易にインストールできます。
Windows の場合は scoop を使うと同じようにインストールできます。
インストール方法の詳細についてはこちらをご参照ください。
https://learn.hashicorp.com/tutorials/terraform/install-cli

```sh
# for Mac
$ brew install terraform
# for Windows
> scoop install terraform
```

正常にインストールできたか次のコマンドで確認します。

```sh
$ terraform -version
```

次に AWC CLI をインストールします。これも brew でインストールします。（Windows は scoop）
他 OS の場合はこちらを見てください。
https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html

```sh
# for Mac
$ brew install awscli
# for Windows
> scoop install aws
```

次のコマンドでインストールができたか確認します。

```sh
aws --version
```

作業ディレクトリを作成し、移動します。

```sh
$ install -m 0755 terraform-aws-sample
$ cd terraform-aws-sample
```

### terraform の環境準備

terraform で AWS にインスタンスを構築するに当たり、AWSへのアクセスが必要なため、アクセスキーとシークレットキーを環境変数に設定します。

```sh
# AWSのアクセスキー
$ export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
# AWSのシークレットキー
$ export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
# リージョン名
$ export AWS_DEFAULT_REGION="<YOUR_AWS_DEFAULT_REGION>"
```

ではファイルを用意しましょう。
ファイル名を "main.tf" として、次の内容を記載します。

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "ap-northeast-1"
}
```

一度ファイルを保存して閉じます。
正しく記載できているか確認するため、次のコマンドを実行します。

```sh
$ terraform validate
Success! The configuration is valid.
```

次にterraformの環境準備をします。（providerに沿ったプラグインのダウンロード）

```sh
$ terraform init
```

### EC2インスタンスの定義

再度、main.tfを開きます。
terraformではresourceでEC2などを定義するため、provider の下辺りに resourceを記述していきます。

```terraform
provider "aws" {
  region = "ap-northeast-1"
}

# ↓を追記
resource "aws_instance" "demo" {
  ami           = "ami-02c3627b04781eada" # AmazonLinux2のAMI ID
  instance_type = "t2.micro"

  tags = {
    Name = "tf-demo"
  }
}
```

resourceの構文は、

```
resource "リソースタイプ" "任意の定義名" {
  リソース内の設定値
}
```

の形式で記述します。
今回はEC2インスタンスの定義のため、リソースタイプは"aws_instance"となります。

resource内の内容はリソースタイプによって異なります。EC2インスタンスの場合は、"ami"と"instance_type"が最低あれば構築できます。

ami に指定する値はAMIカタログなどで表示されているAMI IDです。

![スクリーンショット 2022-06-07 11.35.42.png](https://rga.qiita.com/files/0cf0a2fb-233d-91ea-917a-3d7782ff5a22.png)

instance_type はそのままですね。今回は"t2.micro"にしています。

最後に、tagsという部分について説明。
インスタンスのタグを指定する箇所ですが、今回はインスタンス名を設定しています。

### terraform を使ってリソースの生成・削除

以下のコマンドでどのような構成でリソースが作成されるか確認しましょう。

```sh
$ terraform plan
```

実行計画（どういう構成で環境構築を行うかの構成内容）を確認できます。
計画内容に問題なければ次のコマンドで環境構築を行います。

```sh
$ terraform apply
```

上記コマンド実行後次の確認が出るので"yes"と入力し、処理をすすめるとインスタンスが生成されます。

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

EC2の画面側で確認すると作成したインスタンスが確認できるかと思います。

![スクリーンショット 2022-06-07 11.51.28.png](https://rga.qiita.com/files/01ebafd9-52c1-fe21-f935-ee2a4c834c2c.png)

確認できたら忘れず削除しておきましょう。

```sh
$ terraform destroy
```

### ログイン用SSH鍵の設定

このままではインスタンスにアクセスできないため、SSH鍵を設定します。
先程の resource の中に設定を追加します。

```terraform
resource "aws_instance" "app_server" {
  ami           = "ami-830c94e3"
  instance_type = "t2.micro"
  key_name      = "登録済みSSH鍵名"

  tags = {
    Name = "TFSampleInstance"
  }
}
```

AWSマネージメントコンソールの「キーペア」で登録済みSSH鍵を確認し、対象の鍵名を指定します。







そして、先程と同様に「terraform apply」でインスタンスを作成します。

```sh
$ terraform apply
$ terraform show | grep -e "public_dns"
# => ec2-18-181-217-113.ap-northeast-1.compute.amazonaws.com など接続DNS名を取得
```

「terraform show」の行では、生成されたインスタンスにアクセスするため公開ドメイン名を取得しています。
