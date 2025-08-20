# Audit Report for Tetherground USD Token

    ## Tools Used
    - Slither, Echidna, Foundry
    - Mythril - Manticore

    ## Summary
    ✔️ Configured and generated successfully.  
    📁 Detaylı çıktılar 'audit/' klasöründe bulunabilir.
    

    # Markdown → HTML
    try:
        import markdown
        with open(audit_md_path, "r") as f:
            html_content = markdown.markdown(f.read())
        with open(os.path.join(docs_dir, "audit_report.html"), "w") as f:
            f.write(html_content)
    except ImportError:
        print("⚠️ markdown modülü eksik. `pip install markdown` ile yükleyin.")

    # HTML → PDF
    try:
        import pdfkit
        pdfkit.from_string(html_content, os.path.join(docs_dir, "audit_report.pdf"))
    except Exception as e:
        print("⚠️ PDF üretimi için 'pdfkit' ve sistemde 'wkhtmltopdf' kurulu olmalı!")

## Token Overview
- Name: Tetherground USD
- Symbol: USDTg
- Decimals: 18
- Total Supply: 10000000000

## Features
This token includes the following features:
- Capped supply
- Burnable
- Pausable
- Blacklist and rescue functionality
- Upgradeable (if selected)
- Fee-on-transfer routing
- Governance compatibility

## Use Cases
Tetherground USD (USDTg) is designed for:
- Decentralized finance applications
- Stable medium of exchange
- Multi-chain operability

## Security & Audit
This project includes full audit configurations:
- Slither, Echidna, Foundry
- Mythril, Manticore, Tenderly (if selected)

