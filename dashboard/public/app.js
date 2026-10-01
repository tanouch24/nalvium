const api = window.NALVIUM_API_URL || 'http://localhost:8000';
const token = () => document.querySelector('#admin-token').value;
const connection = document.querySelector('#connection');
const escapeHtml = value => String(value ?? '').replace(/[&<>'\"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','\"':'&quot;'}[c]));

async function get(path) {
  const response = await fetch(api + '/v1/admin/' + path, {headers: {'X-Admin-Token': token()}});
  if (!response.ok) throw new Error('admin request failed');
  return response.json();
}
async function loadDashboard() {
  if (!token()) return;
  connection.textContent = 'Chargement…';
  try {
    const values = await Promise.all([get('metrics'), get('leads'), get('professionals'), get('community/posts'), get('community/reports'), get('repair-requests'), get('service-offerings'), get('ai-costs'), get('commerce')]);
    const metrics = values[0], leads = values[1], professionals = values[2], community = values[3].posts || [], reports = values[4].reports || [], repairs = values[5].requests || [], services = values[6].offerings || [], aiCosts = values[7], commerce = values[8];
    document.querySelector('#metric-diagnostics').textContent = metrics.diagnostics;
    document.querySelector('#metric-resolved').textContent = metrics.diagnostics ? Math.round(metrics.resolved / metrics.diagnostics * 100) + '%' : '0%';
    document.querySelector('#metric-leads').textContent = metrics.leads;
    document.querySelector('#metric-safety').textContent = metrics.safety_stops;
    document.querySelector('#repairs-body').innerHTML = repairs.length ? repairs.map(item => '<tr><td><b>' + escapeHtml(item.description) + '</b><small>' + escapeHtml(item.first_name) + '</small></td><td>' + escapeHtml(item.postal_code) + '</td><td><i class="pill amber">' + escapeHtml(item.status) + '</i></td><td>' + escapeHtml(item.source) + '</td><td>' + escapeHtml((item.created_at || '').slice(0, 10)) + '</td></tr>').join('') : '<tr><td colspan="5">Aucune demande de dépannage.</td></tr>';
    document.querySelector('#services-list').innerHTML = services.length ? services.map(item => '<div class="pro"><div><b>' + escapeHtml(item.title) + '</b><small>' + escapeHtml(item.pricing_type) + ' · ' + escapeHtml(item.active ? 'Actif' : 'Inactif') + '</small></div></div>').join('') : '<p class="muted">Aucun service configuré.</p>';
    connection.dataset.aiCosts = JSON.stringify(aiCosts);
    const commerceEvents = commerce.events || {};
    document.querySelector('#commerce-status').textContent = Object.keys(commerceEvents).length ? 'Données agrégées, sans diagnostic ni donnée personnelle.' : 'Aucune recherche de matériel enregistrée.';
    document.querySelector('#commerce-list').innerHTML = (commerce.items || []).length ? commerce.items.map(item => '<div class="pro"><b>' + escapeHtml(item.name) + '</b><small>' + escapeHtml(item.count) + ' recherche(s)</small></div>').join('') : '';
    document.querySelector('#community-body').innerHTML = community.length ? community.map(post => '<tr><td><b>' + escapeHtml(post.title) + '</b><small>' + escapeHtml(post.author_handle) + '</small></td><td>' + escapeHtml(post.status) + '</td><td>' + escapeHtml(post.moderation_status) + '</td><td>' + escapeHtml((post.created_at || '').slice(0, 10)) + '</td><td><button class="moderate-post" data-id="' + escapeHtml(post.id) + '" data-status="' + (post.moderation_status === 'approved' ? 'restricted' : 'approved') + '">' + (post.moderation_status === 'approved' ? 'Restreindre' : 'Approuver') + '</button></td></tr>').join('') : '<tr><td colspan="5">Aucune publication.</td></tr>';
    document.querySelector('#reports-body').innerHTML = reports.length ? reports.map(report => '<tr><td>' + escapeHtml(report.target_type) + ' · ' + escapeHtml(report.target_id) + '</td><td>' + escapeHtml(report.reason) + '</td><td>' + escapeHtml(report.status) + '</td><td>' + escapeHtml((report.created_at || '').slice(0, 10)) + '</td></tr>').join('') : '<tr><td colspan="4">Aucun signalement.</td></tr>';
    document.querySelectorAll('.moderate-post').forEach(button => button.addEventListener('click', async () => { await fetch(api + '/v1/admin/community/posts/' + button.dataset.id + '/moderation', {method: 'PATCH', headers: {'X-Admin-Token': token(), 'content-type': 'application/json'}, body: JSON.stringify({moderation_status: button.dataset.status})}); await loadDashboard(); }));
    document.querySelector('#leads-body').innerHTML = leads.length ? leads.map(lead => '<tr><td><b>' + escapeHtml(lead.summary) + '</b><small>' + escapeHtml(lead.first_name) + ' · consentement enregistré</small></td><td>' + escapeHtml(lead.trade) + '</td><td>' + escapeHtml(lead.city) + '</td><td><i class="pill amber">' + escapeHtml(lead.status) + '</i></td><td>' + escapeHtml((lead.created_at || '').slice(0, 10)) + '</td></tr>').join('') : '<tr><td colspan="5">Aucun lead enregistré.</td></tr>';
    document.querySelector('#pros-list').innerHTML = professionals.length ? professionals.map(pro => '<div class="pro"><span class="avatar">' + escapeHtml(pro.business_name.slice(0,2).toUpperCase()) + '</span><div><b>' + escapeHtml(pro.business_name) + '</b><small>' + escapeHtml(pro.email) + ' · ' + escapeHtml(pro.verification_status) + '</small></div><button class="toggle-pro" data-id="' + escapeHtml(pro.id) + '" data-active="' + pro.active + '">' + (pro.active ? 'Désactiver' : 'Activer') + '</button><i class="pill ' + (pro.active ? 'green' : 'gray') + '">' + (pro.active ? 'Actif' : 'Inactif') + '</i></div>').join('') : '<p class="muted">Aucun professionnel configuré.</p>';
    document.querySelectorAll('.toggle-pro').forEach(button => button.addEventListener('click', async () => { await fetch(api + '/v1/admin/professionals/' + button.dataset.id, {method: 'PATCH', headers: {'X-Admin-Token': token(), 'content-type': 'application/json'}, body: JSON.stringify({active: button.dataset.active !== 'true'})}); await loadDashboard(); }));
    connection.textContent = 'Données backend chargées.';
  } catch (_) { connection.textContent = 'Connexion refusée : vérifiez le token et le backend.'; }
}
document.querySelector('#connect').addEventListener('click', loadDashboard);
document.querySelector('#add-pro').addEventListener('click', async () => {
  if (!token()) return;
  const business_name = window.prompt('Nom commercial');
  const phone = window.prompt('Téléphone');
  const email = window.prompt('Email');
  const city = window.prompt('Ville couverte');
  if (!business_name || !phone || !email || !city) return;
  await fetch(api + '/v1/admin/professionals', {method: 'POST', headers: {'X-Admin-Token': token(), 'content-type': 'application/json'}, body: JSON.stringify({business_name, legal_name: '', phone, email, trade: 'plombier', city, active: true})});
  await loadDashboard();
});
