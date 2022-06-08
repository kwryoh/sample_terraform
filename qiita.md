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
  instance_type = "t3.micro"

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

### terraform の準備

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
  instance_type = "t3.micro"

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

## ネットワークの作成

前述でEC2インスタンスを作成したので、そのインスタンスが外部接続可能なようにネットワークの準備をします。
それぞれのリソースの細かい説明は割愛します。

![terraform-sample.png](https://rga.qiita.com/files/4a6bf65a-2537-f035-287c-80986e0c2102.png)

### VPC

VPCを構成するため、以下のコードをさきほどの main.tf に追記してください。

```terraform
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

```sh
$ terraform plan
```

で確認し、

```sh
$ terraform apply
```

でVPCを適用させます。

AWSマネジメントコンソールからVPCが作成されているか確認します。

### サブネット

次に、サブネットを構成します。以下のコードをさきほどの main.tf に追記してください。

```terraform
resource "aws_subnet" "demo_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

でサブネットを適用させます。

AWSマネジメントコンソールで作成されているか確認します。

### Internet Gateway

外部アクセスのためInternet Gatewayを作ります。。以下のコードを main.tf に追記してください。

```terraform
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

で適用させます。AWSマネジメントコンソールで作成されているか確認します。

### Route Table

Internet Gatewayを通じてアクセスができるよう、ルーティング設定をします。
以下のコードを main.tf に追記します。

```terraform
resource "aws_route_table" "demo_rt_tbl" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

また、ルーティング設定とサブネットの紐付け設定も追記します。

```terraform
resource "aws_route_table_association" "demo_rt_assoc" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt_tbl.id

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

で適用させます。

### Security Group

最後にファイアウォール設定をします。
今回はSSH接続とWeb接続を許可します。
まず、大枠のセキュリティグループを作成します。

```terraform
resource "aws_security_group" "demo_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "tf-demo"
  }
}
```

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

次に、ここのルールを追記していきます。

```terraform
# Outbound 設定
resource "aws_security_group_rule" "demo_egress_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.demo_sg.id
}

# SSH接続
resource "aws_security_group_rule" "demo_allow_ssh" {
  description       = "Allow SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo_sg.id
}

# HTTP接続
resource "aws_security_group_rule" "demo_allow_http" {
  description       = "Allow HTTP"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo_sg.id
}
```

一通り記述したら、

```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

で適用させます。

これで一通りの準備が整いました。（ElasticIPを使いたい場合はElasticIPのリソースも作成します）

## EC2の外部公開

EC2を作成したVPC、セキュリティグループに所属させることで外部からアクセスできるようにしていきます。

### EC2をサブネットに所属させる

初めに記載したEC2リソースの記述を下記のように編集します。

```terraform
resource "aws_instance" "demo" {
  ami                    = "ami-02c3627b04781eada" # AmazonLinux2のAMI ID
  instance_type          = "t3.micro"
  # ↓追記
  subnet_id              = aws_subnet.demo_subnet.id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  # ↑ここまで

  tags = {
    Name = "tf-demo"
  }
}
```

いつもどおり

```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

で適用させます。


### ログイン用SSH鍵を設定

最後にSSH接続ができるようにインスタンスに設置する鍵を指定します。
なお、SSH鍵は先にAWSマネジメントコンソールで作成しておきます。

先程のEC2インスタンスのリソースに設定を追加します。

```terraform
resource "aws_instance" "demo" {
  ami                    = "ami-02c3627b04781eada" # AmazonLinux2のAMI ID
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.demo_subnet.id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  key_name               = "登録済みSSH鍵名"

  tags = {
    Name = "tf-demo"
  }
}
```

記述したら


```sh
$ terraform plan
```

で適用内容を確認し、

```sh
$ terraform apply
```

で適用します。

次のコマンドで外部公開のDNS名を取得し、接続できるか試してみましょう。

```sh
$ terraform show | grep -e "public_dns"
# => ec2-18-181-217-113.ap-northeast-1.compute.amazonaws.com など接続DNS名を取得
```


## 最後に

今回細かくVPCからEC2のリソースを定義しました。
AWSの各リソースを自分で定義しないといけないためクラウド環境の構成をよく知っていないと使いこなすのは難しいです。
ただ、構成をコードの形で定義しておくと、デプロイでミスを減らせれるし、人にもお任せできるのでよいツールだなと思いました。

まだまだ説明できていない機能があり、もっと複雑な構成（インスタンスを2つ、3つ作るなど）ができるので、
クラウドを使う場合はなるべくterraformで定義しようと思います。

※ちなみにterraformではEC2インスタンスの停止はできないので、停止したい場合はマネジメントコンソールでの操作が必要です。


最終的なコードは次のとおりとなります。

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

# Provider
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region = "ap-northeast-1"

  # 全てのリソースに同じタグを設定する
  default_tags {
    tags = {
      Name = "tf-demo"
    }
  }
}

# Local Variables
# https://www.terraform.io/language/values/locals
locals {
  ami_id      = "ami-02c3627b04781eada" # AmazonLinux2のAMI
  my_key_name = "rkw_home"
}

# Instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/instance
resource "aws_instance" "demo" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.demo_subnet.id
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
  key_name               = local.my_key_name
}

# VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "demo_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Internet Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
}

# Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "demo_rt_tbl" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }
}

# Route Table Associate
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "demo_rt_assoc" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt_tbl.id
}

# Security Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "demo_sg" {
  vpc_id      = aws_vpc.demo_vpc.id
  description = "Terraform Demo"
}

# Security Group Rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "demo_egress_allow_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo_sg.id
}
resource "aws_security_group_rule" "demo_allow_ssh" {
  description       = "Allow SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["133.32.176.221/32"]
  security_group_id = aws_security_group.demo_sg.id
}

resource "aws_security_group_rule" "demo_allow_http" {
  description       = "Allow HTTP"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.demo_sg.id
}
```
