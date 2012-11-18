[color]
        ui = true
[core]
        autocrlf = false
        pager = more
[alias]
        lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
        st = status
        br = branch

        sts = "status --porcelain"
        stss = !sh -c 'git status --porcelain' -
        stl = "!git status --porcelain | cut -b 4-"
        stu = "!git status --porcelain | grep '?' | cut -b 4-"

[http]
	sslcainfo = @H@/.ssh/curl-ca-bundle.crt
[user]
    name = gitoliteadm
    email = gitoliteadm@mail.com

[push]
    default = simple
