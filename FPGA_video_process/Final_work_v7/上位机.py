import serial
import tkinter as tk
import threading
import tkinter.font as tkFont
from tkinter import ttk
import time


def get_interpolation_method(num):
    if num == '1':
        return '最近邻插值算法'
    elif num == '2':
        return '双线性插值算法'
    elif num == '3':
        return '双立方插值算法'
    else:
        return '未知插值算法'


def read_serial_data():
    ser = serial.Serial("COM14", 115200, timeout=0.01)
    while True:
        #time.sleep(0.5)
        data = ser.read(26)
        if data:
            rec_str = data.decode()
            modified_string = rec_str.replace('@', '')

            first_dollar_index = modified_string.find('$')

            if first_dollar_index != -1:
                modified_string = modified_string[:first_dollar_index] + '*' + modified_string[first_dollar_index + 1:]

            second_dollar_index = modified_string.find('$', first_dollar_index)

            if second_dollar_index != -1:
                modified_string = modified_string[:second_dollar_index] + '*' + modified_string[second_dollar_index + 1:]

            third_dollar_index = modified_string.find('$', second_dollar_index)

            if third_dollar_index != -1:
                modified_string = modified_string[:third_dollar_index] + '*' + modified_string[third_dollar_index + 1:]

            fourth_dollar_index = modified_string.find('$', third_dollar_index + 1)

            if fourth_dollar_index != -1:
                modified_string = modified_string[:fourth_dollar_index]

            code = data.decode()
            if '*' in modified_string:
                parts = modified_string.split('*')
                for i in range(len(parts)):
                    if parts[i].lstrip('0').isdigit():
                        parts[i] = str(int(parts[i]))
                content = '分辨率为' + parts[0] + '*' + parts[1] \
                          + '\n横向缩放比为' + parts[2] + '\n纵向缩放比为' + parts[3] \
                          + '\n使用的算法为：' + get_interpolation_method(code[-1])
            else:
                content = "无信号"
            content_text.delete('1.0', tk.END)  # 清空文本框
            content_text.insert(tk.END, content + "\n")
            window.update_idletasks()
        else:
            content_text.delete('1.0', tk.END)  # 清空文本框
            content_text.insert(tk.END, '无信号' + "\n")
            window.update_idletasks()
        window.after(500, read_serial_data)


window = tk.Tk()
window.attributes("-alpha", 0.8)
#window.title("分辨率/算法监视器")
window.overrideredirect(True)
window.window_size = '180x98'
window.geometry(f"{window.window_size}+480+385")

custom_font = tkFont.Font(family="Helvetica", size=13)

content_text = tk.Text(window, height=5, width=20, fg="red", bg="black",  font=custom_font)
content_text.pack()

# 创建一个线程来执行串口数据读取操作
serial_thread = threading.Thread(target=read_serial_data)
serial_thread.daemon = True
serial_thread.start()

window.mainloop()
