+++
title = 'Lsky Pro部署'
date = '2023-06-30T20:53:07+08:00'
description = '部署Lsky Pro及Typora插件的使用'
featured = false          # show in carousel
categories = ['']
tags = ['折腾']
cover = 'cover.jpg'      # image in the same directory, or external URL
toc = true               # show table of contents sidebar
draft = false
+++

记录一下搭建Lsky Pro的过程

## 操作环境

+ Ubuntu 20.04
+ Lsky Pro v2.1
+ PHP==8.0.29
+ Nginx 1.18.0(Ubuntu)
+ mysql==8.0.33

## 安装

首先建议阅读[官方文档](https://docs.lsky.pro/)

### 下载源文件

[项目地址](https://github.com/lsky-org/lsky-pro)

下载文件并且解压

```bash
wget https://github.com/lsky-org/lsky-pro/releases/download/2.1/lsky-pro-2.1.zip
unzip lsky-pro-2.1.zip -d /var/www/lsky # 目录改为Nginx项目的根目录
```

PS：注意解压后的目录中有若干隐藏文件无法直接使用`mv`指令转移，如果使用`mv`转移还请注意。

### 安装PHP8.0

#### 安装php

Lsky Pro V2.1 要求PHP >= 8.0.2，Ubuntu可以直接安装{{<fnref 1>}}

```bash
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php # 使用ondrej/php添加PHP 8.0包和其他所需要的PHP扩展
sudo apt update # 更新包索引和包列表

# 安装PHP8.0
sudo apt install php8.0
# 安装php-fpm
sudo apt install php8.0-fpm
```

#### 安装拓展

Lsky Pro需要以下拓展：

+ BCMath PHP 扩展
+ Ctype PHP 扩展
+ DOM PHP 拓展
+ Fileinfo PHP 扩展
+ JSON PHP 扩展
+ Mbstring PHP 扩展
+ OpenSSL PHP 扩展
+ PDO PHP 扩展
+ Tokenizer PHP 扩展
+ XML PHP 扩展
+ Imagick 拓展

可以直接执行：

```bash
# 包含了部分常用拓展，也可以只安装官方要求的拓展
sudo apt install php8.0-common php8.0-mysql php8.0-xml php8.0-xmlrpc php8.0-curl php8.0-gd php8.0-imagick php8.0-cli php8.0-dev php8.0-imap php8.0-mbstring php8.0-opcache php8.0-soap php8.0-zip php8.0-intl php8.0-bcmath -y
```

### 配置Nginx

在`/etc/nginx/sites-enabled`下(Nginx配置文件，根据安装方式不同可能略有差异)，新建配置文件，配置Server。下面提供我的配置文件以供参考。

```
server {
	listen 80;  //端口
	listen [::]:80;
	server_name example.com;  //域名，或者IP地址

	root /var/www/lsky/public;  //lsky的项目路径，注意要在public下

	index index.html index.htm index.php;
	client_max_body_size 10M;  //nginx附件最大上传大小
	
	if (!-e $request_filename) {
        	rewrite ^(.*)$ /index.php$1 last; 
    	}

	location / {
		try_files $uri $uri/ /index.php?$query_string; // 伪静态
	}

	location ~ \.php$ {
       		include fastcgi.conf;
        	include fastcgi_params;
        	fastcgi_pass unix:/run/php/php8.0-fpm.sock; // php-fpm路径
    	}
	
}
```

然后重启Nginx服务。

```bash
systemctl restart nginx
```

然后打开nginx配置文件中设置的域名以及端口号，成功则会出现以下界面：

![image-20230630181600274](https://static.246266.xyz/i/2023/06/30/649eab65a3e7e.png#vwid=1920&vhei=1080)



### Lsky初始化

出现上述界面后点击下一步，配置数据库。

![安装界面](https://static.246266.xyz/i/2023/06/30/649eabe608f67.png#vwid=1920&vhei=1080)

新建数据库，填入数据库名称以及密码。管理员账户和密码是Lsky后台的管理账户。点击立即安装后即可成功安装。

成功后可以进入管理页面。

![管理页面](https://static.246266.xyz/i/2023/06/30/649eade44bbce.png#vwid=1920&vhei=998)

到此Lsky Pro就算安装完毕。



## Typora + LANKONG

### Typora和Picgo配置

[LANKONG项目地址](https://github.com/hellodk34/picgo-plugin-lankong)

使用Typora编写文章可以使用LANKONG插件自动上传图片，省去了手动上传的繁琐。

LANKONG是picgo的一个插件。picgo依赖于Node.js,首先需要下载Node.js,[下载地址](https://nodejs.cn/download/)，选择对应的版本下载。安装过可以忽略。

Typora集成了两种方式，一种是[Picgo app](https://github.com/Molunerfinn/PicGo)，另一种是[Picgo-Core](https://github.com/PicGo/PicGo-Core)。前一种是图像化界面，第二种是命令行的形式。不过由于Picgo app每次需要调用打开应用程序，因此在此选择Picgo-Core的方式。

#### 使用Typora下载

在Typora->文件->偏好设置->图像->上传服务设定中，选择PicGo-Core(command line)，点击下载或更新。

![Typora设置](https://static.246266.xyz/i/2023/06/30/649eb126aac39.png#vwid=674&vhei=174)

下载完成后，进行LANKONG插件的安装，此处参考LANKONG项目下的[issue #10](https://github.com/hellodk34/picgo-plugin-lankong/issues/10),首先打开picgo的安装位置，winwos下一般在`C:\Users\用户名\AppData\Roaming\Typora\picgo\win64\`,在命令行执行：

```powershell
C:\Users\用户名\AppData\Roaming\Typora\picgo\win64> ./picgo.exe install lankong
```

#### 使用全局npm安装

如果你已经安装过`node.js`,那么你可以选择使用已安装的`node.js`进行picgo-core的安装，参考[官方教程](https://picgo.github.io/PicGo-Core-Doc/),依次执行如下命令：

```bash
# 安装picgo
npm install picgo -g  # 或者 yarn global add picgo
```

安装完成后，进入picgo的目录下，默认在`/node安装路径/node_modules/picgo/bin`,安装lankong插件：

```bash
cd /node安装路径/node_modules/picgo/bin

# 安装lankong【For windwos】
node picgo install lankong

# 或执行 ./picgo install lankong
```



然后在Typora->文件->偏好设置->图像->上传服务设定中，选择**自定义命令**，然后输入：

```cmd
# For Windows
node \path\to\node_modules\picgo\bin\picgo upload
```



![自定义命令](C:\Users\GuGuDaDa\AppData\Roaming\Typora\typora-user-images\image-20230926094759133.png)

### 配置LSKY PRO图床

安装完成后，打开picgo的配置文件。

picgo 的默认配置文件为`~/.picgo/config.json`。其中`~`为用户目录。不同系统的用户目录不太一样。

linux 和 macOS 均为`~/.picgo/config.json`。

windows 则为`C:\Users\你的用户名\.picgo\config.json`

编辑如下：

```json
{
  "picBed": {
    "current": "lankong",
    "uploader": "lankong",
    "lankong": {
      "lskyProVersion": "V2", //兰空版本V1,V2
      "server": "https://example.com", //示例: https://example.com，只需填写Serve Name而非API链接
      "token": "", //认证 token 信息
      "strategyId": "", //选填, V1以及V2使用默认存储策略时请留空
      "albumId": "",
      "permission": "public",  // 默认为私有(private(default)),即不再画廊公开
      "ignoreCertErr": true, //是否忽略证书错误, 如果上传失败提示证书过期请设为true
      "syncDelete": false //是否同步删除，只支持V2
    }
  },
  "picgoPlugins": {
    "picgo-plugin-lankong": true
  }
}
```

其中Token根据lsky pro版本的不同，获取方式不同，V2版本可以通过以下方式获取：

1. cURL(lankong提供)：

   ```bash
   curl --location --request POST 'https://your.domain/api/v1/tokens' \
   --form 'email="your_email@address"' \
   --form 'password="your_passwd"'  //email和password替换为自己的账号密码
   ```

   

2. python：

   ```python
   import requests
   import json
   
   if __name__ == "__main__":
       # 将对应数据换成自己的数据
       post_dict = {'email': 'email', 'password': 'password'}
       header = {
           "Accept": "application/json",
           "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                         "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36"
   }
   
       r1 = requests.post("https://example.com/api/v1/tokens", data=post_dict, headers=header)
       print("token-->" + r1.text)
   ```

   返回结果：

   ![返回结果](https://static.246266.xyz/i/2023/06/30/649eb65f57d47.png#vwid=1286&vhei=55)

   将token中的返回数据与`"Bearer "`拼接(注意有一个空格),填入到配置文件中去，然后在Typora中测试。

   ![测试结果](https://static.246266.xyz/i/2023/06/30/649eb756d8641.png#vwid=598&vhei=652)

   安装成功。

{{<refers title="参考">}}
{{< refer num="1" source="https://zhuanlan.zhihu.com/p/402297155" url="https://zhuanlan.zhihu.com/p/402297155">}}
如何在Ubuntu中将PHP升级到8.0
{{< /refer >}}
{{</refers>}}
