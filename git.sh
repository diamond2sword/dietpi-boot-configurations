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
	GH_EMAIL="diamond2sword@gmail.com"
	GH_NAME="diamond2sword"
	GH_PASSWORD="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"
	SSH_KEY_PASSPHRASE="for(;C==0;){std::cout<<C++}"
	DEFAULT_GIT_COMMAND_NAME="GIT_RESET"
	THIS_FILE_NAME="git.sh"
	BRANCH_NAME="main"
	COMMIT_NAME="update project"
	PROJECT_NAME="project"
	SSH_DIR_NAME=".ssh"
	SSH_KEY_FILE_NAME="id_rsa"
	ROOT_PATH="/root"
	REPO_PATH="$ROOT_PATH/$REPO_NAME"
	SSH_TRUE_DIR="$ROOT_PATH/$SSH_DIR_NAME"
	SSH_REPO_DIR="$REPO_PATH/$SSH_DIR_NAME"
	REPO_URL="https://github.com/$GH_NAME/$REPO_NAME"
	SSH_REPO_URL="git@github.com:$GH_NAME/$REPO_NAME"
}

exec_git_command () {
	main () {
		git_command=$1; shift
		args="$@"
		reset_credentials
		eval $git_command "$args"
	}

	is_var_set () {
		git_command=$1
		! [[ "$git_command" ]] && {
			return
		}
		return 0
	}

	main "$@"
}

declare_git_commands () {
	reset_credentials () {
		cd "$REPO_PATH"
		git config --global --unset credential.helper
		git config --system --unset credential.helper
		git config --global user.name "$GH_NAME"
		git config --global user.email "$GH_EMAIL"
	}

	push () {
		cd "$REPO_PATH"
		git add .
		git commit -m "$COMMIT_NAME"
		git remote set-url origin "$SSH_REPO_URL"
		ssh_auth_eval "git push -u origin $BRANCH_NAME"
	}

	reset () {
		rm -r -f "$REPO_PATH"
		mkdir -p "$REPO_PATH"
		cd "$REPO_PATH"
		git clone "$REPO_URL" "$REPO_PATH"
	}

	config () {
		KEY_NAME=$1; shift
		NEW_VALUE=$1
		[[ "$KEY_NAME" == "REPO_NAME" ]] && {
			REPO_NAME="$NEW_VALUE"
		}

		sed -i '{
			/^declare_strings/{
				:start
				/\n\}/!{
					/'"$KEY_NAME"'=/{
						b found
					}
					n
					b start
				}
				b exit
				:found
				/^declare_strings/!{
					s/'"$KEY_NAME"'=.*$/'"$KEY_NAME"'="'"$NEW_VALUE"'"/
				}
			}
			:exit
		}' $ROOT_PATH/$REPO_NAME/$THIS_FILE_NAME
	}
}

add_ssh_key_to_ssh_agent () {
	mkdir -p "$SSH_TRUE_DIR"
	cp -f $(eval echo $SSH_REPO_DIR/*) "$SSH_TRUE_DIR"
	chmod 600 "$SSH_TRUE_DIR/$SSH_KEY_FILE_NAME"
	eval "$(ssh-agent -s)"
	ssh_auth_eval ssh-add $SSH_TRUE_DIR/$SSH_KEY_FILE_NAME
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

