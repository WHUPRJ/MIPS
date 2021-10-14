import argparse
import struct
import serial
from sys import stdout

matrix = [[0] * 81 for _ in range(25)]
pos = [0, 0, 0, 0]  # p1y p2y bx by


def init_serial(pipe_path, baudrate):
    global tty
    # tty = serial.serial_for_url('loop://')
    # return True
    tty = serial.Serial(port=pipe_path, baudrate=baudrate)
    tty.reset_input_buffer()
    return True


def print_map():
    print("\033c", end="")
    ball = '●'
    bat = '█'
    border = '█'

    print(hello)
    for i in range(83):
        print(border, end='')
    print()
    for i in matrix:
        print(border, end='')
        for j in i:
            if j == 0:
                print(' ', end='')
            elif j == 1:
                print(bat, end='')
            else:
                print(ball, end='')
        print(border)
    for i in range(83):
        print(border, end='')
    print()


def clear_map():
    matrix[pos[0]][4] = 0
    matrix[pos[0] - 1][4] = 0

    matrix[pos[1]][76] = 0
    matrix[pos[1] - 1][76] = 0

    matrix[pos[3]][pos[2]] = 0


def update_map():
    matrix[pos[0]][4] = 1
    matrix[pos[0] - 1][4] = 1

    matrix[pos[1]][76] = 1
    matrix[pos[1] - 1][76] = 1

    matrix[pos[3]][pos[2]] = 2


def main():
    global hello
    hello = ''

    pause = False
    while True:
        line = tty.readline()[:-1]
        if line[0] < 128:
            if line == b'resume':
                pause = False
                print_map()
                continue
            if line == b'pause':
                pause = True
                print('>>>', end=' ')
                stdout.flush()
                continue
            try:
                hello = line.decode('utf-8')
            except:
                pass
        else:
            if pause:
                continue
            if len(line) != 4:
                continue
            clear_map()
            pos[0] = 25 - (line[0] - 128)
            pos[1] = 25 - (line[1] - 128)
            pos[2] = line[2] - 129
            pos[3] = 25 - (line[3] - 128)
            update_map()
            print_map()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ping Pong MIPS UI')
    parser.add_argument('-s', '--serial', default='/dev/tty.usbserial-FTAMV947', type=str,
                        help='Serial port name (e.g. /dev/ttyACM0, COM3)')
    parser.add_argument('-b', '--baud', default=57600, type=int,
                        help='Serial port baud rate')
    args = parser.parse_args()

    if not init_serial(args.serial, args.baud):
        print('Failed to open serial port')
        exit(1)

    # tty.write('Ping Pong.\n'.encode('utf-8'))
    # tty.write(serial.to_bytes([128 + 3, 128 + 12, 128 + 40, 128 + 15, 0x0a]))
    # tty.write('pause\n'.encode('utf-8'))
    # tty.write('resume\n'.encode('utf-8'))
    # tty.write(serial.to_bytes([128 + 12, 128 + 8, 128 + 32, 128 + 19, 0x0a]))

    main()
