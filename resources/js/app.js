import './bootstrap';
import '../css/app.css';
import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import { createApp } from 'vue';
import HRDashboard from './components/HRDashboard.vue';

createApp(HRDashboard).mount('#app');
