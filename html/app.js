// NUI controller for death screen & EMS dispatch tablet
const overlay = document.getElementById('overlay');
const ekgState = document.getElementById('ekg-state');
const panicKey = document.getElementById('panic-key');
const distress = document.getElementById('distress');
const subtext = document.querySelector('.subtext');
const dispatchWrapper = document.getElementById('dispatch');
const callList = document.getElementById('call-list');
const unitList = document.getElementById('unit-list');
const closeDispatchBtn = document.getElementById('dispatch-close');
const patientCard = document.getElementById('patient-card');
const patientStatus = document.getElementById('patient-status');
const patientHeart = document.getElementById('patient-heart');

const defaultDistressText = distress ? distress.innerHTML : '';
const defaultSubtext = subtext ? subtext.textContent : '';

function setState(state) {
    ekgState.classList.remove('unstable', 'flatline');
    let text = 'Stable';

    if (state === 'unstable') {
        text = 'Unstable';
        ekgState.classList.add('unstable');
    } else if (state === 'flatline') {
        text = 'Flatline';
        ekgState.classList.add('flatline');
    }

    ekgState.textContent = text;
}

function toggleOverlay(visible, state, panicLabel) {
    if (panicLabel && panicKey) {
        panicKey.textContent = panicLabel;
    }

    if (distress) {
        distress.classList.remove('sent');
        distress.innerHTML = defaultDistressText;
    }
    if (subtext) {
        subtext.textContent = defaultSubtext;
    }

    if (visible) {
        overlay.classList.remove('hidden');
    } else {
        overlay.classList.add('hidden');
    }
    if (state) {
        setState(state);
    }
}

function markDistressSent() {
    if (distress) {
        distress.classList.add('sent');
        distress.textContent = 'Dispatch ping transmitted // EMS notified';
    }
    if (subtext) {
        subtext.textContent = 'Stay calm. Signal locked to EMS network.';
    }
}

function formatCoords(coords) {
    if (!coords) return 'Unknown';
    const { x = 0, y = 0, z = 0 } = coords;
    return `${x.toFixed(1)}, ${y.toFixed(1)}, ${z.toFixed(1)}`;
}

function renderCalls(calls = []) {
    callList.innerHTML = '';
    calls.forEach((call) => {
        const card = document.createElement('div');
        card.className = 'call-card';

        const assignedUnits = call.assigned ? Object.keys(call.assigned) : [];

        const createdAgo = call.createdAt ? Math.max(0, Math.floor(Date.now() / 1000) - call.createdAt) : 0;
        const minutes = Math.floor(createdAgo / 60);
        const seconds = createdAgo % 60;

        card.innerHTML = `
            <div class="header">
                <span>Call #${call.id || '?'} - ${call.reason || 'Dispatch'} (P${call.priority || 2})</span>
                <span class="status">${(call.status || 'waiting').toUpperCase()}</span>
            </div>
            <div class="meta">Caller: ${call.callerName || 'Unbekannt'} | Coords: ${formatCoords(call.coords)} | ${minutes}m ${seconds}s ago</div>
            <div class="meta">Units: ${assignedUnits.length > 0 ? assignedUnits.join(', ') : 'Unassigned'}</div>
            <div class="actions">
                <button data-action="dispatch-status" data-id="${call.id}" data-status="assigned" data-coords='${JSON.stringify(call.coords || {})}'>Assign</button>
                <button class="secondary" data-action="dispatch-status" data-id="${call.id}" data-status="on_scene">On Scene</button>
                <button class="danger" data-action="dispatch-status" data-id="${call.id}" data-status="completed">Complete</button>
            </div>
        `;

        callList.appendChild(card);
    });
}

function renderUnits(units = []) {
    unitList.innerHTML = '';
    units.forEach((unit) => {
        const card = document.createElement('div');
        card.className = 'unit-card';
        card.innerHTML = `
            <div class="header">
                <span>${unit.callsign ? `[${unit.callsign}] ` : ''}${unit.name || 'Unit'}</span>
                <span class="status">${(unit.status || 'available').toUpperCase()}</span>
            </div>
        `;
        unitList.appendChild(card);
    });
}

function toggleDispatch(visible, calls, units) {
    if (visible) {
        dispatchWrapper.classList.remove('hidden');
        renderCalls(calls || []);
        renderUnits(units || []);
    } else {
        dispatchWrapper.classList.add('hidden');
    }
    dispatchWrapper.classList.remove('flash');
}

function togglePatientCard(visible, status, heart) {
    if (visible) {
        patientCard.classList.remove('hidden');
        patientStatus.textContent = status || '--';
        patientHeart.textContent = heart ? `${heart} bpm` : '--';
    } else {
        patientCard.classList.add('hidden');
    }
}

function nui(eventName, data = {}) {
    fetch(`https://clp_medic/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'toggle') {
        toggleOverlay(data.visible, data.status, data.panicLabel);
    }

    if (data.action === 'setEKGState') {
        setState(data.status);
    }

    if (data.action === 'showDeathscreen') {
        toggleOverlay(true, data.status, data.panicLabel);
    }

    if (data.action === 'hideDeathscreen') {
        toggleOverlay(false, data.status, data.panicLabel);
    }

    if (data.action === 'dispatchSent') {
        markDistressSent();
    }

    if (data.action === 'dispatchOpen') {
        toggleDispatch(true, data.calls || [], data.units || []);
    }

    if (data.action === 'dispatchUpdate') {
        renderCalls(data.calls || []);
        renderUnits(data.units || []);
    }

    if (data.action === 'dispatchClose') {
        toggleDispatch(false);
    }

    if (data.action === 'dispatchPing') {
        dispatchWrapper.classList.remove('flash');
        void dispatchWrapper.offsetWidth; // restart animation/class
        dispatchWrapper.classList.add('flash');
    }

    if (data.action === 'patientOverlay') {
        togglePatientCard(data.visible, data.status, data.heart);
    }
});

if (closeDispatchBtn) {
    closeDispatchBtn.addEventListener('click', () => {
        toggleDispatch(false);
        nui('dispatchClose');
    });
}

document.addEventListener('click', (event) => {
    const target = event.target;
    if (target && target.dataset) {
        if (target.dataset.action === 'dispatch-status') {
            const id = Number(target.dataset.id);
            const status = target.dataset.status;
            const coords = target.dataset.coords ? JSON.parse(target.dataset.coords) : null;
            nui('dispatchStatus', { id, status, coords });
        }
        if (target.dataset.action === 'unit-status') {
            nui('unitStatus', { status: target.dataset.status });
        }
    }
});
