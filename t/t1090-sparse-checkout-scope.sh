#!/bin/sh

test_description='sparse checkout scope tests'

. ./test-lib.sh

test_expect_success 'setup' '
	echo "initial" >a &&
	echo "initial" >b &&
	echo "initial" >c &&
	git add a b c &&
	git commit -m "initial commit"
'

test_expect_success 'create feature branch' '
	git checkout -b feature &&
	echo "modified" >b &&
	echo "modified" >c &&
	git add b c &&
	git commit -m "modification"
'

test_expect_success 'perform sparse checkout of master' '
	git config --local --bool core.sparsecheckout true &&
	echo "!/*" >.git/info/sparse-checkout &&
	echo "/a" >>.git/info/sparse-checkout &&
	echo "/c" >>.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c
'

test_expect_success 'merge feature branch into sparse checkout of master' '
	git merge feature &&
	test_path_is_file a &&
	test_path_is_missing b &&
	test_path_is_file c &&
	test "$(cat c)" = "modified"
'

test_expect_success 'return to full checkout of master' '
	git checkout feature &&
	echo "/*" >.git/info/sparse-checkout &&
	git checkout master &&
	test_path_is_file a &&
	test_path_is_file b &&
	test_path_is_file c &&
	test "$(cat b)" = "modified"
'


test_expect_success 'checkout does not delete items outside the sparse checkout file' '
	git checkout master &&
	git config core.gvfs 8 &&
	git checkout -b outside &&
	echo "new file1" >d &&
	git add d &&
	git commit -m "branch initial" &&
	echo "new file1" >e &&
	git add e &&
	git commit -m "skipped worktree" &&
	git update-index --skip-worktree e &&
	echo "/d" >.git/info/sparse-checkout &&
	git checkout HEAD^ &&
	test_path_is_file d &&
	test_path_is_file e
'

test_done
