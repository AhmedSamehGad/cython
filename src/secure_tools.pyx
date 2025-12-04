# cython: language_level=3
# distutils: define_macros=NPY_NO_DEPRECATED_API=NPY_1_7_API_VERSION

import random
import string
import hashlib
import secrets
import os
import base64
import math
import socket
import qrcode
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
import psutil
import urllib.parse
import requests

# Type declarations for Cython optimization
cdef list PUNCTUATION_LIST = list(string.punctuation)
cdef list ASCII_UPPER = list(string.ascii_uppercase)
cdef list ASCII_LOWER = list(string.ascii_lowercase)
cdef list DIGITS = list(string.digits)

def generate_password(int length=12):
    """Generate a secure password with given length."""
    cdef list required, remaining, password_list
    cdef str password
    
    if length < 4:
        length = 4
    
    required = [
        secrets.choice(ASCII_UPPER),
        secrets.choice(ASCII_LOWER),
        secrets.choice(DIGITS),
        secrets.choice(PUNCTUATION_LIST),
    ]
    
    everything = string.ascii_letters + string.digits + string.punctuation
    remaining = [secrets.choice(everything) for _ in range(length - len(required))]
    password_list = required + remaining
    random.shuffle(password_list)
    password = "".join(password_list)
    
    return password

def generate_passphrase():
    """Generate a memorable passphrase."""
    cdef list words = [
        "apple", "banana", "cherry", "dragon", "elephant", "flamingo", "giraffe", 
        "honey", "igloo", "jaguar", "koala", "lemon", "mango", "narwhal", "octopus",
        "penguin", "quokka", "raccoon", "strawberry", "tiger", "umbrella", "violet",
        "whale", "xylophone", "yellow", "zebra", "alpha", "bravo", "charlie", "delta"
    ]
    
    return '-'.join(secrets.choice(words) for _ in range(4))

def evaluate_password(str password):
    """Evaluate password strength and provide feedback."""
    cdef bint booleanFlag1, booleanFlag2, booleanFlag3, booleanFlag4
    cdef int score
    cdef str special_syms = "!@#$%^&*()_+-=[]{|;':\",.<}>/?"
    cdef str result
    
    booleanFlag1 = len(password) >= 12
    booleanFlag2 = any(ch.isnumeric() for ch in password)
    booleanFlag3 = any(ch.isupper() for ch in password)
    booleanFlag4 = any(ch in special_syms for ch in password)
    
    score = sum([25 if flag else 0 for flag in [booleanFlag1, booleanFlag2, booleanFlag3, booleanFlag4]])
    
    if all([booleanFlag1, booleanFlag2, booleanFlag3, booleanFlag4]):
        result = f"Strong Password\nScore: {score}%\nLength: {len(password)} characters"
    else:
        result = "Password needs improvement:\n"
        if not booleanFlag1:
            result += f"• Minimum 12 characters (currently {len(password)})\n"
        if not booleanFlag2:
            result += "• Add numbers\n"
        if not booleanFlag3:
            result += "• Add uppercase letters\n"
        if not booleanFlag4:
            result += "• Add special characters (!@#$ etc.)\n"
        result += f"Score: {score}%"
    
    return result

def caesar_cipher(str text, int shift):
    """Encrypt text using Caesar cipher."""
    cdef str result = ""
    cdef int base
    cdef str char
    
    for char in text:
        if char.isalpha():
            base = ord('A') if char.isupper() else ord('a')
            result += chr((ord(char) - base + shift) % 26 + base)
        else:
            result += char
    
    return result

def caesar_decipher(str text, int shift):
    """Decrypt Caesar cipher text."""
    return caesar_cipher(text, -shift)

def caesar_bruteforce(str text):
    """Brute force all possible Caesar cipher shifts."""
    cdef list results = []
    cdef int shift
    
    for shift in range(26):
        decrypted = caesar_decipher(text, shift)
        results.append(f"Shift {shift:2d}: {decrypted}")
    
    return "\n".join(results)

def rot13(str text):
    """Apply ROT13 transformation."""
    return caesar_cipher(text, 13)

def xor_encrypt(data, key):
    """XOR encrypt data with key."""
    cdef bytearray encrypted
    cdef int i
    
    if isinstance(data, str):
        data = data.encode()
    if isinstance(key, str):
        key = key.encode()
    
    encrypted = bytearray()
    for i, byte in enumerate(data):
        encrypted.append(byte ^ key[i % len(key)])
    
    return bytes(encrypted)

def xor_decrypt(data, key):
    """XOR decrypt data with key."""
    return xor_encrypt(data, key)

def xor_encrypt_string(str text, str key):
    """XOR encrypt string and return Base64 encoded result."""
    encrypted = xor_encrypt(text, key)
    return base64.b64encode(encrypted).decode()

def xor_decrypt_string(str text, str key):
    """Decrypt Base64 encoded XOR encrypted string."""
    try:
        data = base64.b64decode(text)
        decrypted = xor_decrypt(data, key)
        return decrypted.decode()
    except:
        return "Decryption failed - check key"

def aes_generate_key():
    """Generate AES encryption key."""
    return Fernet.generate_key()

def aes_encrypt(data, key):
    """Encrypt data using AES."""
    if isinstance(data, str):
        data = data.encode()
    
    fernet = Fernet(key)
    return fernet.encrypt(data)

def aes_decrypt(data, key):
    """Decrypt AES encrypted data."""
    fernet = Fernet(key)
    decrypted = fernet.decrypt(data)
    
    try:
        return decrypted.decode()
    except:
        return decrypted

def encode_base64(str text):
    """Base64 encode text."""
    return base64.b64encode(text.encode()).decode()

def decode_base64(str text):
    """Base64 decode text."""
    decoded = base64.b64decode(text.encode())
    
    try:
        return decoded.decode()
    except:
        return str(decoded)

def calculate_md5(str filename):
    """Calculate MD5 hash of file."""
    cdef hash_md5 = hashlib.md5()
    
    with open(filename, "rb") as file:
        for chunk in iter(lambda: file.read(4096), b""):
            hash_md5.update(chunk)
    
    return hash_md5.hexdigest()

def calculate_sha256(str filename):
    """Calculate SHA256 hash of file."""
    cdef sha = hashlib.sha256()
    
    with open(filename, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            sha.update(chunk)
    
    return sha.hexdigest()

def generate_qr(str text):
    """Generate QR code from text."""
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(text)
    qr.make(fit=True)
    img = qr.make_image(fill='black', back_color='white')
    img.save('qr.png')
    return 'qr.png'

def secure_delete(str filename):
    """Securely delete file by overwriting."""
    cdef int length
    cdef int i
    
    if os.path.exists(filename):
        with open(filename, 'rb+') as f:
            length = os.path.getsize(filename)
            for i in range(3):
                f.seek(0)
                f.write(os.urandom(length))
                f.flush()
            f.seek(0)
            f.write(b'\x00' * length)
        os.remove(filename)
        return True
    
    return False

def validate_ip(str ip):
    """Validate IP address format."""
    cdef list parts = ip.split('.')
    cdef str part
    cdef int num
    
    if len(parts) != 4:
        return False
    
    for part in parts:
        if not part.isdigit():
            return False
        num = int(part)
        if num < 0 or num > 255:
            return False
    
    return True

def port_scan(str target):
    """Scan common ports on target IP."""
    cdef list open_ports = []
    cdef list common_ports = [21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 
                             443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080]
    cdef int port
    cdef sock
    
    for port in common_ports:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((target, port))
            if result == 0:
                open_ports.append(port)
            sock.close()
        except:
            continue
    
    return open_ports

def entropy(str password):
    """Calculate password entropy in bits."""
    cdef int pool_size = 0
    cdef float entropy_value
    
    if any(c.islower() for c in password):
        pool_size += 26
    if any(c.isupper() for c in password):
        pool_size += 26
    if any(c.isdigit() for c in password):
        pool_size += 10
    if any(c in string.punctuation for c in password):
        pool_size += 32
    
    if pool_size == 0:
        return 0
    
    entropy_value = len(password) * math.log2(pool_size)
    return round(entropy_value, 2)

def detect_keylogger():
    """Detect suspicious processes that might be keyloggers."""
    cdef list suspicious_processes = []
    cdef list keylogger_names = ['keylogger', 'logkeys', 'pykeylogger', 
                                 'refog', 'microkeylogger', 'ardamax']
    cdef proc
    cdef str name
    
    try:
        for proc in psutil.process_iter(['name']):
            try:
                name = proc.info['name'].lower()
                if any(keylogger in name for keylogger in keylogger_names):
                    suspicious_processes.append(name)
            except:
                continue
    except:
        pass
    
    return suspicious_processes

def wordlist_generator(str word):
    """Generate password variations from base word."""
    cdef list variations = []
    cdef str word_lower = word.lower()
    cdef dict leet_map = {'a': '@', 'e': '3', 'i': '1', 'o': '0', 's': '$', 't': '7'}
    cdef str leet_word = ''
    cdef str char
    
    variations.append(word_lower)
    variations.append(word_lower.capitalize())
    variations.append(word_lower.upper())
    variations.append(word_lower + '123')
    variations.append(word_lower + '123!')
    variations.append('123' + word_lower)
    variations.append(word_lower + '2024')
    variations.append(word_lower + '@')
    variations.append(word_lower + '!')
    variations.append('@' + word_lower)
    variations.append('!' + word_lower)
    
    for char in word_lower:
        leet_word += leet_map.get(char, char)
    
    variations.append(leet_word)
    variations.append(leet_word.capitalize())
    
    with open('wordlist.txt', 'w') as f:
        f.write('\n'.join(variations))
    
    return 'wordlist.txt'

def generate_username():
    """Generate random username."""
    cdef list first_names = ['alex', 'jordan', 'taylor', 'casey', 'riley', 
                            'quinn', 'morgan', 'drew', 'blake', 'cameron']
    cdef list last_names = ['smith', 'johnson', 'williams', 'brown', 'jones', 
                           'garcia', 'miller', 'davis', 'rodriguez', 'martinez']
    cdef str numbers = ''.join(random.choices(string.digits, k=random.randint(1, 4)))
    cdef list separators = ['', '.', '_', '-']
    cdef str sep = random.choice(separators)
    cdef int style = random.randint(1, 5)
    
    if style == 1:
        return random.choice(first_names) + sep + random.choice(last_names)
    elif style == 2:
        return random.choice(first_names)[0] + sep + random.choice(last_names)
    elif style == 3:
        return random.choice(first_names) + sep + random.choice(last_names) + numbers
    elif style == 4:
        return random.choice(first_names) + random.choice(last_names) + numbers
    else:
        return random.choice(first_names) + sep + random.choice(last_names)[0] + numbers

def get_system_info():
    """Get system information."""
    cdef list info = []
    
    try:
        info.append(f"CPU Usage: {psutil.cpu_percent()}%")
        info.append(f"Memory Usage: {psutil.virtual_memory().percent}%")
        info.append(f"Disk Usage: {psutil.disk_usage('/').percent}%")
        info.append(f"Boot Time: {psutil.boot_time()}")
    except:
        info.append("System info unavailable")
    
    return "\n".join(info)

def hash_string(str text, str algorithm='sha256'):
    """Hash text using specified algorithm."""
    if algorithm == 'md5':
        return hashlib.md5(text.encode()).hexdigest()
    elif algorithm == 'sha1':
        return hashlib.sha1(text.encode()).hexdigest()
    elif algorithm == 'sha256':
        return hashlib.sha256(text.encode()).hexdigest()
    elif algorithm == 'sha512':
        return hashlib.sha512(text.encode()).hexdigest()
    else:
        return hashlib.sha256(text.encode()).hexdigest()

def reverse_string(str text):
    """Reverse string."""
    return text[::-1]

def url_encode(str text):
    """URL encode text."""
    return urllib.parse.quote(text)

def url_decode(str text):
    """URL decode text."""
    return urllib.parse.unquote(text)

def hex_encode(str text):
    """Hexadecimal encode text."""
    return text.encode().hex()

def hex_decode(str hex_string):
    """Hexadecimal decode text."""
    return bytes.fromhex(hex_string).decode()

def morse_encode(str text):
    """Encode text to Morse code."""
    cdef dict morse_dict = {
        'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.',
        'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---',
        'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---',
        'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
        'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--',
        'Z': '--..', '0': '-----', '1': '.----', '2': '..---', '3': '...--',
        '4': '....-', '5': '.....', '6': '-....', '7': '--...', '8': '---..',
        '9': '----.', ' ': '/'
    }
    
    cdef list encoded = []
    cdef str char
    
    for char in text.upper():
        if char in morse_dict:
            encoded.append(morse_dict[char])
        else:
            encoded.append(char)
    
    return ' '.join(encoded)

def morse_decode(str morse_code):
    """Decode Morse code to text."""
    cdef dict morse_dict = {
        '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
        '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
        '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
        '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
        '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
        '--..': 'Z', '-----': '0', '.----': '1', '..---': '2', '...--': '3',
        '....-': '4', '.....': '5', '-....': '6', '--...': '7', '---..': '8',
        '----.': '9', '/': ' '
    }
    
    cdef list decoded = []
    cdef str symbol
    
    for symbol in morse_code.split(' '):
        if symbol in morse_dict:
            decoded.append(morse_dict[symbol])
        else:
            decoded.append(symbol)
    
    return ''.join(decoded)

def generate_random_key(int length=32):
    """Generate random hex key."""
    return secrets.token_hex(length)

def password_strength_meter(str password):
    """Detailed password strength analysis."""
    cdef int score = 0
    cdef list feedback = []
    cdef list strength_levels = ["Very Weak", "Weak", "Fair", "Good", "Strong", "Very Strong"]
    cdef str result
    
    if len(password) >= 8:
        score += 1
    else:
        feedback.append("Password too short (min 8 characters)")
    
    if len(password) >= 12:
        score += 1
    
    if any(c.islower() for c in password) and any(c.isupper() for c in password):
        score += 1
    else:
        feedback.append("Add both lowercase and uppercase letters")
    
    if any(c.isdigit() for c in password):
        score += 1
    else:
        feedback.append("Add numbers")
    
    if any(c in string.punctuation for c in password):
        score += 1
    else:
        feedback.append("Add special characters")
    
    result = f"Strength: {strength_levels[min(score, 5)]} ({score}/5)\n"
    if feedback:
        result += "Suggestions:\n" + "\n".join(f"• {item}" for item in feedback)
    
    return result

def check_pwned_password(str password):
    """Check password against known breaches."""
    cdef str sha1_hash, prefix, suffix, url, h
    cdef int count
    
    try:
        sha1_hash = hashlib.sha1(password.encode()).hexdigest().upper()
        prefix, suffix = sha1_hash[:5], sha1_hash[5:]
        url = f"https://api.pwnedpasswords.com/range/{prefix}"
        response = requests.get(url, timeout=5)
        hashes = response.text.splitlines()
        
        for h in hashes:
            if h.startswith(suffix):
                count = int(h.split(':')[1])
                return f"Password found in {count:,} data breaches!"
        
        return "Password not found in known breaches"
    except:
        return "Could not check password (network error)"

def file_integrity_check(str file1, str file2):
    """Compare two files for integrity."""
    cdef str hash1, hash2
    
    try:
        hash1 = calculate_sha256(file1)
        hash2 = calculate_sha256(file2)
        
        if hash1 == hash2:
            return "Files are identical\n" + f"SHA256: {hash1}"
        else:
            return "Files are different\n" + f"File1 SHA256: {hash1}\nFile2 SHA256: {hash2}"
    except Exception as e:
        return f"Error: {str(e)}"

def generate_rsa_keys():
    """Generate RSA public/private key pair."""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    public_key = private_key.public_key()
    
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    
    public_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    
    return private_pem.decode(), public_pem.decode()

def analyze_file_type(str filename):
    """Analyze file type using MIME detection."""
    try:
        import mimetypes
        file_type, _ = mimetypes.guess_type(filename)
        return f"File Type: {file_type or 'Unknown'}"
    except:
        return "File type analysis unavailable"

def get_network_info():
    """Get network information."""
    cdef list info = []
    cdef str hostname, ip_address
    cdef tuple interface_addresses
    cdef address
    
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        info.append(f"Hostname: {hostname}")
        info.append(f"IP Address: {ip_address}")
        
        interfaces = psutil.net_if_addrs()
        for interface_name, interface_addresses in interfaces.items():
            for address in interface_addresses:
                if str(address.family) == 'AddressFamily.AF_INET':
                    info.append(f"Interface {interface_name}: {address.address}")
    except:
        info.append("Network info unavailable")
    
    return "\n".join(info)

def monitor_processes():
    """Monitor top 20 processes."""
    cdef list processes = []
    cdef proc
    
    try:
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                processes.append(proc.info)
            except:
                continue
        return processes[:20]
    except:
        return []