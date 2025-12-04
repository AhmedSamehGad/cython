from setuptools import setup, find_packages, Extension
from Cython.Build import cythonize
import numpy as np
import os

# Define extensions for Cython compilation
extensions = [
    Extension(
        "src.secure_tools",
        ["src/secure_tools.pyx"],
        include_dirs=[np.get_include()],
        define_macros=[('NPY_NO_DEPRECATED_API', 'NPY_1_7_API_VERSION')],
        extra_compile_args=['/O2' if os.name == 'nt' else '-O3', '-march=native'],
        language="c"
    ),
    Extension(
        "src.secure_app",
        ["src/secure_app.pyx"],
        extra_compile_args=['/O2' if os.name == 'nt' else '-O3'],
        language="c"
    )
]

setup(
    name="secure_suite_pro",
    version="3.2.0",
    description="Secure Suite Pro - Professional Security Toolkit with Accessibility Features",
    author="Secure Suite Team",
    author_email="support@securesuite.pro",
    packages=find_packages(),
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            'language_level': "3",
            'boundscheck': False,
            'wraparound': False,
            'initializedcheck': False,
            'nonecheck': False,
            'cdivision': True,
            'infer_types': True
        },
        annotate=False  # Set to True to generate HTML annotation for optimization
    ),
    install_requires=[
        'customtkinter>=5.2.0',
        'pyttsx3>=2.90',
        'cryptography>=41.0.0',
        'psutil>=5.9.0',
        'qrcode>=7.4.2',
        'requests>=2.31.0',
        'Cython>=3.0.0',
        'numpy>=1.24.0',
    ],
    python_requires='>=3.8',
    entry_points={
        'console_scripts': [
            'secure-suite=src.secure_app:main',
        ],
    },
    include_package_data=True,
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: End Users/Desktop',
        'Topic :: Security',
        'Topic :: Utilities',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS',
    ],
    keywords='security password encryption hash file network accessibility',
    project_urls={
        'Source': 'https://github.com/yourusername/secure-suite-pro',
        'Bug Reports': 'https://github.com/yourusername/secure-suite-pro/issues',
    },
)