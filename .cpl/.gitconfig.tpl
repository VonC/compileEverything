[color]
        ui = true
[core]
        autocrlf = false
        pager = more
[alias]
        lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative
        lga = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --all
        st = status
        br = branch

        sts = "status --porcelain"
        stss = !sh -c 'git status --porcelain' -
        stl = "!git status --porcelain | cut -b 4-"
        stu = "!git status --porcelain | grep '?' | cut -b 4-"
        restore = "!f() { xxgit=1 git checkout $(git rev-list -n 1 HEAD -- $1)~1 -- $(xxgit=1 git diff --name-status $(git rev-list -n 1 HEAD -- $1)~1 | grep '^D' | cut -f 2); }; f"

[http]
	sslcainfo = @H@/.ssh/curl-ca-bundle.crt
[user]
    name = GitLab
    email = gitoliteadm@mail.com

[push]
    default = simple
[credential]
    helper = cache --timeout 9000
