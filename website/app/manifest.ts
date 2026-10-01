import { MetadataRoute } from 'next';
export default function manifest(): MetadataRoute.Manifest { return { name:'NALVIUM', short_name:'NALVIUM', description:'Montrez le problème. NALVIUM vous guide.', start_url:'/', display:'standalone', background_color:'#07111F', theme_color:'#07111F', lang:'fr' } }
