#!/bin/bash

main () (
	declare_strings "$@"
	declare_git_commands
	declare_ssh_auth_eval
	add_ssh_key_to_ssh_agent
	exec_git_command "$@"
)

declare_strings () {
	REPO_NAME="dietpi-boot-configurations"
	BRANCH_NAME="main"
	GH_EMAIL="diamond2sword@gmail.com"
	GH_NAME="diamond2sword"
	DEFAULT_GIT_COMMAND_NAME="push"
	THIS_FILE_NAME="git.bash"
	PROJECT_NAME="project"
	SSH_DIR_NAME=".ssh"
	SSH_KEY_FILE_NAME="id_rsa"
	ROOT_PATH="$HOME"
	REPO_PATH="$ROOT_PATH/$REPO_NAME"
	SSH_TRUE_DIR="$ROOT_PATH/$SSH_DIR_NAME"
	SSH_REPO_DIR="$REPO_PATH/$SSH_DIR_NAME"
	COMMIT_NAME="update project"
	{
		ssh_key_passphrase_path="$HOME/ssh-key-passphrase.txt"
		if [ ! -f "$ssh_key_passphrase_path" ]; then
			echo "Error: $ssh_key_passphrase_path not found containing a ssh key pasphrase"
			exit
		fi
		SSH_KEY_PASSPHRASE="$(cat "$ssh_key_passphrase_path")"
	}
	{
		gh_pass_path="$HOME/github-personal-token.txt"
		if [ ! -f "$gh_pass_path" ]; then
			echo "Error: $gh_pass_path not found containing a personal token"
			exit
		fi
		GH_PASSWORD="$(cat "$gh_pass_path")"
	}
	REPO_URL="https://github.com/$GH_NAME/$REPO_NAME"
	SSH_REPO_URL="git@github.com:$GH_NAME/$REPO_NAME"
}

exec_git_command () {
	main () {
		local git_command="$1"; shift
		local args="$*"
		reset_credentials
		if [[ "$git_command" == "git" ]]; then
			ssh_auth_eval "git $args"
			return
		fi	
		eval "$git_command" "$args"
	}

	is_var_set () {
		local git_command="$1"
		! [[ "$git_command" ]] && {
			return
		}
		return 0
	}

	main "$@"
}

declare_git_commands () {
	update_repos () {
		local repo_list=($(echo $(gh repo list --source --json name | sed 's/,/\n/g' | sed 's/^.*:"//g' | sed 's/"}.*$//g')))
		for repo_name in "${repo_list[@]}"; do
			install_git_bash_to_repo "$repo_name"
		done
	}

	install_git_bash_to_repo () {
		local repo_name="$1"
		# get branch name
		local branch_name="$(git rev-parse --abbrev-ref HEAD)"
		echo -en "\n\nDoing $repo_name/$branch_name\n\n"
		clone "$repo_name"
		repo_path="$HOME/$repo_name"
		# copy files
		cp -rf "$REPO_PATH/git.bash" "$REPO_PATH/.ssh" "$repo_path"
		# change git.bash content
		echo "$(cat "$repo_path/git.bash" | sed "s/REPO_NAME=\".*\"/REPO_NAME=\"$repo_name\"/" | sed "s/BRANCH_NAME=\".*\"/BRANCH_NAME=\"$branch_name\"/")" > "$repo_path/git.bash"
	}

	fix_ahead_commits () {
		cp -r "$REPO_PATH/"* "$REPO_PATH.bak"
		git checkout "$BRANCH_NAME"
		git pull -s recursive -X theirs
		git reset --hard origin/$BRANCH_NAME
	}

	rebase () {
		cd "$REPO_PATH" || exit
		ssh_auth_eval "git pull origin $BRANCH_NAME --rebase --autostash"
		ssh_auth_eval "git rebase --continue"
	}

	clone () {
		local repo_name="$1"
		git clone "https://$GH_NAME:$GH_PASSWORD@github.com/$GH_NAME/$repo_name" "$HOME/$repo_name"
	}

	reset_credentials () {
		cd "$REPO_PATH" || return
		git config --global --unset credential.helper
		git config --system --unset credential.helper
		git config --global user.name "$GH_NAME"
		git config --global user.email "$GH_EMAIL"
	}

	push () {
		cd "$REPO_PATH" || exit
		git add .
		git commit -m "$COMMIT_NAME"
		git remote set-url origin "$SSH_REPO_URL"
		ssh_auth_eval "git push -u origin $BRANCH_NAME"
	}

	reclone () {
		local repo_name="$1"
		rm -rf "$HOME/$repo_name"
		clone "$repo_name"
	}
}

add_ssh_key_to_ssh_agent () {
	mkdir -p "$SSH_TRUE_DIR"
	cp -f $(eval echo "$SSH_REPO_DIR/"*) "$SSH_TRUE_DIR"
	chmod 600 "$SSH_TRUE_DIR/$SSH_KEY_FILE_NAME"
	eval "$(ssh-agent -s)"
	ssh_auth_eval ssh-add "$SSH_TRUE_DIR/$SSH_KEY_FILE_NAME"
}


declare_ssh_auth_eval () {
eval "$(cat <<- "EOF"
	ssh_auth_eval () {
		command="$@"
		ssh_key_passphrase="$SSH_KEY_PASSPHRASE"
		expect << EOF2
			spawn $command
			expect {
				-re {Enter passphrase for} {
					send "$ssh_key_passphrase\r"
					exp_continue
				}
				-re {Are you sure you want to continue connecting} {
					send "yes\r"
					exp_continue
				}
				eof
			}
		EOF2
	}
EOF
)"
}

main "$@"
