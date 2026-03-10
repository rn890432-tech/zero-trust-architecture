import psycopg2

def create_tenant(name, email):
    conn = psycopg2.connect("dbname=soc user=postgres password=postgres host=postgres")
    cur = conn.cursor()
    cur.execute("INSERT INTO tenants (tenant_name) VALUES (%s) RETURNING id", (name,))
    tenant_id = cur.fetchone()[0]
    cur.execute("INSERT INTO users (tenant_id, email, role) VALUES (%s, %s, %s)", (tenant_id, email, 'admin'))
    conn.commit()
    cur.close()
    conn.close()
    return tenant_id
