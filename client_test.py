import socket

def send_data(ip, port, message):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((ip, port))
            s.sendall(message.encode())
            print(f"Data sent to {ip}:{port}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    target_ip = "127.0.0.1"  # Change this to the target IP
    target_port = 4000       # Change this to the target port
    message = "Ping!"        # Message to send
    
    send_data(target_ip, target_port, message)

