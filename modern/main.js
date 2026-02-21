import 'bootstrap/dist/css/bootstrap.min.css';
import * as bootstrap from 'bootstrap';
import './main.modern.css';

import { Calendar } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';

const calEl = document.getElementById('calendar');
const settingsEl = document.getElementById('settings');

function parseBool(v) {
  return String(v).toLowerCase() === 'true';
}

function parseHiddenDays(v) {
  if (!v) return [];
  const clean = String(v).replace(/[\[\]]/g, '');
  return clean
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)
    .map((x) => Number(x));
}

function mapLegacyView(v) {
  const m = {
    month: 'dayGridMonth',
    agendaWeek: 'timeGridWeek',
    agendaDay: 'timeGridDay',
    basicWeek: 'dayGridWeek',
    basicDay: 'dayGridDay'
  };
  return m[v] || v || 'dayGridMonth';
}

function mapLegacyToolbar(v) {
  return String(v || '')
    .replace(/\bmonth\b/g, 'dayGridMonth')
    .replace(/\bagendaWeek\b/g, 'timeGridWeek')
    .replace(/\bagendaDay\b/g, 'timeGridDay')
    .replace(/\bbasicWeek\b/g, 'dayGridWeek')
    .replace(/\bbasicDay\b/g, 'dayGridDay');
}

function normalizeEventsUrl(raw) {
  let u = raw || '';
  if (!u) return '/index.cfm?controller=eventdata&action=getevents&type=index&key=0&format=json';
  // legacy route generated like /index.cfm/eventdata/getevents/index&format=json
  if (u.includes('&format=') && !u.includes('?')) {
    u = u.replace('&format=', '?format=');
  }
  if (!u.includes('controller=eventdata')) {
    // safest fallback for this migrated app
    return '/index.cfm?controller=eventdata&action=getevents&type=index&key=0&format=json';
  }
  return u;
}

function openEventModal(html) {
  const body = document.getElementById('eventmodal-body');
  const modalEl = document.getElementById('eventmodal');
  if (!body || !modalEl) return;
  body.innerHTML = html;
  const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
  modal.show();
}

if (calEl && settingsEl) {
  const s = settingsEl.dataset;
  const eventsURL = normalizeEventsUrl(calEl.dataset.eventsurl);
  const eventURL = calEl.dataset.eventurl;
  const addURL = calEl.dataset.addurl;
  const key = s.key || '';
  const urlRewriting = (calEl.dataset.urlrewriting || 'on').toLowerCase();

  try {
    const calendar = new Calendar(calEl, {
      plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
      initialView: mapLegacyView(s.defaultview),
      weekends: parseBool(s.weekends),
      firstDay: Number(s.firstday || 0),
      slotMinTime: s.mintime || '00:00:00',
      slotMaxTime: s.maxtime || '24:00:00',
      allDaySlot: parseBool(s.alldayslot),
      weekNumbers: parseBool(s.weeknumbers),
      hiddenDays: parseHiddenDays(s.hiddendays),
      height: 'auto',
      headerToolbar: {
        left: mapLegacyToolbar(s.headerleft || 'prev,next today'),
        center: mapLegacyToolbar(s.headercenter || 'title'),
        right: mapLegacyToolbar(s.headerright || 'dayGridMonth,timeGridWeek,timeGridDay')
      },
      events(fetchInfo, successCallback) {
        fetch(eventsURL, { method: 'GET' })
          .then((r) => (r.ok ? r.json() : []))
          .then((data) => successCallback(Array.isArray(data) ? data : []))
          .catch(() => successCallback([]));
      },
      dateClick(info) {
        const d = info.dateStr;
        const joiner = addURL.includes('?') ? '&' : '?';
        let target = `${addURL}${joiner}d=${encodeURIComponent(d)}`;
        if (urlRewriting === 'off') {
          target = `${addURL}&key=${encodeURIComponent(key)}&d=${encodeURIComponent(d)}`;
        }
        window.location.href = target;
      },
      eventClick(info) {
        const eventId = info.event.id;
        let target = `${eventURL}/${eventId}?format=json`;
        if (urlRewriting === 'off') {
          target = `${eventURL}&key=${eventId}&format=json`;
        }
        fetch(target)
          .then((r) => r.text())
          .then((html) => openEventModal(html))
          .catch(() => {});
      }
    });

    calendar.render();
  } catch (e) {
    // keep page usable even if calendar fails
    calEl.innerHTML = '<div class="alert alert-warning">Calendar failed to initialize.</div>';
  }
}
