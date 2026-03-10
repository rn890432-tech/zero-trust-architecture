import sys
try:
    from weasyprint import HTML
except ImportError:
    print("Error: 'weasyprint' module not found. Please install it using 'pip install weasyprint'.")
    sys.exit(1)

if len(sys.argv) != 3:
    print("Usage: python html2pdf.py input.html output.pdf")
    sys.exit(1)

input_html = sys.argv[1]
output_pdf = sys.argv[2]

HTML(input_html).write_pdf(output_pdf)
print(f"PDF generated: {output_pdf}")
