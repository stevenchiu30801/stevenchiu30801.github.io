---
title: Hexo with GitHub Page
date: 2020-07-29 11:55:45
tags:
    - Hexo
    - Setup
---

My original blog is written with [Octopress](http://octopress.org/) and then I migrated to [Hexo](https://hexo.io/). This post guides one to build up a blog with Hexo. <!-- more -->

# Prerequisite

- [NodeJS](https://nodejs.org/en/)
    - [Installing Node.js via binary archive on Linux](https://github.com/nodejs/help/wiki/Installation#how-to-install-nodejs-via-binary-archive-on-linux)

# Install

```bash
npm install hexo-cli -g
```

# Usage

1. Create Hexo blog

    ```bash
    hexo init <folder>
    cd <folder>
    npm install
    ```

2. Create a new page or post

    ```bash
    hexo new "<post>"
    hexo new page "<page>"
    ```

3. Build up the blog

    ```bash
    # Generate static files
    # hexo g
    hexo generate

    # Run the blog at http://localhost:4000
    # hexo s
    hexo server

    # Deploy blog on website (e.g. GitHub)
    # hexo d
    hexo deploy

    # Generate static files and run server
    hexo s -g

    # Generate static files and deploy
    hexo d -g
    ```

4. Change the theme (e.g. NexT)

    ```bash
    git clone https://github.com/theme-next/hexo-theme-next.git themes/next

    # Modify _config.yaml
    cat _config.yaml
    # theme: next
    ```

5. Deploy to GitHub page

    ```bash
    # Install plugin
    npm install hexo-deployer-git --save

    # Modify _config.yaml
    cat _config.yaml
    # deploy:
    #   type: git
    #   repo: 
    #     github: git@github.com:<username>/<username>.github.io.git

    # Deploy
    hexo d
    ```

# My Configuration

- [Hexo](https://github.com/stevenchiu30801/stevenchiu30801.github.io/blob/source/_config.yml)
- [NexT Theme](https://github.com/stevenchiu30801/stevenchiu30801.github.io/blob/source/themes/_config_next.yml)


# Reference

- [Hexo Docs](https://hexo.io/docs/)
- [NexT Docs](http://theme-next.iissnan.com/)
- [如何搭建個人 Blog 使用 Hexo + Gitpage](https://medium.com/@bebebobohaha/%E4%BD%BF%E7%94%A8-hexo-gitpage-%E6%90%AD%E5%BB%BA%E5%80%8B%E4%BA%BA-blog-5c6ed52f23db)
- [Hexo+GitHub，新手也可以快速建立部落格](https://blackmaple.me/hexo-tutorial/)
