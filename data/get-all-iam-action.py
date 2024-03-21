import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import time
import csv
import os
import re

def requests_retry_session(retries=3, backoff_factor=0.3, status_forcelist=(500, 502, 504), session=None):
    """一時的なネットワークエラー向けのリトライ処理"""
    session = session or requests.Session()
    retry = Retry(
        total=retries,
        read=retries,
        connect=retries,
        backoff_factor=backoff_factor,
        status_forcelist=status_forcelist,
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session

def fetch_html(url):
    """指定されたURLからHTMLを取得して解析した結果を返す"""
    session = requests_retry_session()
    response = session.get(url)
    response.encoding = response.apparent_encoding
    return BeautifulSoup(response.text, 'html.parser')

def fetch_service_actions(base_url, service_url):
    """サービスURLからアクション名を抽出してリストで返す"""
    bs_obj = fetch_html(base_url + service_url)
    service_name = bs_obj.find('code', class_='code').text
    table = bs_obj.select_one('.table-container table')
    actions = []

    html_pattern = re.compile(r'.*\.html')

    actions = table.find_all('a', href=lambda href: href and (
        "https://docs.aws.amazon.com/" in href or
        "https://aws.amazon.com/" in href or
        "${APIReferenceDocPage}" in href or
        html_pattern.search(href)
    ))

    format_actions = [
    f'{service_name}:{action.text.replace("[permission only]", "").strip()}\n'
    for action in actions
    ]
    unique_formatted_actions = list(dict.fromkeys(format_actions))

    service_info = [base_url + service_url,service_name,str(len(unique_formatted_actions))]
    return unique_formatted_actions,service_info


# 実行時間計測 開始
start_time = time.time()

# URL 出力先ファイル
base_url = 'https://docs.aws.amazon.com/service-authorization/latest/reference/'
all_service_url = 'reference_policies_actions-resources-contextkeys.html'
actions_file = 'iam_actions.txt'
csv_file_path = 'iam_service.csv'

# 全サービス URL取得
bs_obj = fetch_html(base_url + all_service_url)
links = bs_obj.select('.highlights a')
urls = [link.get('href').lstrip('./') for link in links]

# URLごとにアクション一覧を取得
for relative_url in urls:
    action_list, service_list = fetch_service_actions(base_url, relative_url)

    # アクション一覧 書き込み
    with open(actions_file, 'a') as file:
        file.writelines(action_list)

    # サービス一覧 書き込み
    file_exists = os.path.isfile(csv_file_path)
    with open(csv_file_path, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        if not file_exists:
            writer.writerow(['URL', 'Service Name', 'Number of Actions'])
        writer.writerow(service_list)

    time.sleep(2)

# 実行時間の計算と表示
end_time = time.time()
elapsed_time = end_time - start_time
print(f'実行時間: {elapsed_time:.2f}秒')
