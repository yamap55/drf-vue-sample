ARG PYTHON_VERSION=3.7.6
FROM python:${PYTHON_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

ARG WORKDIR=/workspace
WORKDIR ${WORKDIR}

# Or your actual UID, GID on Linux if not the default 1000
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# change default shell
SHELL ["/bin/bash", "-c"]
RUN chsh -s /bin/bash

# update apt repository
# https://blog.amedama.jp/entry/2019/09/11/234050
# RUN sed -i.bak -e 's%http://[^ ]\+%mirror://mirrors.ubuntu.com/mirrors.txt%g' /etc/apt/sources.list

# Configure apt and install packages
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get -y install sudo vim tzdata \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# install node
# https://github.com/nodesource/distributions/blob/master/README.md#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get install -y nodejs

RUN pip install -U pip

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add sudo support for non-root user
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# terminal setting
RUN wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -O /home/vscode/.git-completion.bash \
    && wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O /home/vscode/.git-prompt.sh \
    && chmod a+x /home/vscode/.git-completion.bash \
    && chmod a+x /home/vscode/.git-prompt.sh \
    && echo -e "\n\
    source ~/.git-completion.bash\n\
    source ~/.git-prompt.sh\n\
    export PS1='\\[\\e]0;\\u@\\h: \\w\\a\\]\${debian_chroot:+(\$debian_chroot)}\\[\\033[01;32m\\]\\u\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\]\\[\\033[1;30m\\]\$(__git_ps1)\\[\\033[0m\\] \\$ '\n\
    " >>  /home/vscode/.bashrc

# install npm packages
COPY ./frontend/package.json ${WORKDIR}/frontend/package.json
RUN npm install --prefix ${WORKDIR}/frontend

# library install
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ENV DEBIAN_FRONTEND=

CMD ["/bin/bash"]
