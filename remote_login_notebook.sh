#!/bin/bash  
# 本地执行  
SERVER=tx-se 
tar -czf - ~/.notebooklm | ssh $SERVER "cd ~ && tar -xzf - && chmod 700 ~/.notebooklm && chmod 600 ~/.notebooklm/*.json"  
  
# 验证  
ssh $SERVER "notebooklm list"
