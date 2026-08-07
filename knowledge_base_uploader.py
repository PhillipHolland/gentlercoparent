#!/usr/bin/env python3
"""
Gentler Coparent Knowledge Base Batch Uploader
Uploads training content from GCP_TRAINING directory to Vercel RAG system
"""

import os
import json
import requests
import time
from pathlib import Path
from typing import Dict, List, Optional
import hashlib
from datetime import datetime

class GCPKnowledgeUploader:
    def __init__(self):
        self.base_url = "https://gentler-coparent-simple-rag.vercel.app"
        self.training_dir = "/Users/phillipholland/Documents/GCP_TRAINING"
        self.upload_log = []
        self.session = requests.Session()
        self.session.timeout = 30
        
        # Content categorization
        self.categories = {
            'state_law': [
                'alabama.txt', 'alaska.txt', 'arizona.txt', 'arkansas.txt', 'california.txt', 
                'colorado.txt', 'connecticut.txt', 'delaware.txt', 'florida.txt', 'georgia.txt',
                'hawaii.txt', 'idaho.txt', 'illinois.txt', 'indiana.txt', 'iowa.txt', 'kansas.txt',
                'kentucky.txt', 'louisiana.txt', 'maine.txt', 'maryland.txt', 'mass.txt', 
                'michigan.txt', 'minnesota.txt', 'mississippi.txt', 'all-states.txt'
            ],
            'coparenting_guidance': [
                'coparenting.txt', 'family code - coparenting.txt', '14 steps of change.txt'
            ],
            'behavioral_psychology': [
                'divorce poison.txt', 'myths about abusers.txt', 'Why Does He Do That.txt',
                'Myths about abusers.txt', 'dangers of couple counceling.txt', 
                'myths excuses and realities.txt'
            ],
            'legal_documents': [
                'TX Family Code.txt', 'qap-handbook.txt'
            ],
            'case_studies': [
                'Another Cancelled Visitation with Seven Minutes Notice .txt',
                'he Enduring Impacts of Reunification Camps: and Next Steps for Legislation .txt'
            ]
        }
    
    def categorize_file(self, filename: str) -> str:
        """Determine content category based on filename"""
        for category, files in self.categories.items():
            if filename in files:
                return category
        return 'general'
    
    def extract_state_from_filename(self, filename: str) -> Optional[str]:
        """Extract state name from state law files"""
        if filename in self.categories['state_law']:
            state_name = filename.replace('.txt', '').replace('mass', 'massachusetts')
            return state_name.title()
        return None
    
    def chunk_content(self, content: str, max_chunk_size: int = 3000) -> List[str]:
        """Split content into manageable chunks for RAG ingestion"""
        # Try to split on natural boundaries (double newlines, then single newlines)
        paragraphs = content.split('\n\n')
        chunks = []
        current_chunk = ""
        
        for paragraph in paragraphs:
            if len(current_chunk + paragraph) < max_chunk_size:
                current_chunk += paragraph + "\n\n"
            else:
                if current_chunk:
                    chunks.append(current_chunk.strip())
                current_chunk = paragraph + "\n\n"
        
        if current_chunk:
            chunks.append(current_chunk.strip())
        
        # If chunks are still too large, split on sentences
        final_chunks = []
        for chunk in chunks:
            if len(chunk) > max_chunk_size:
                sentences = chunk.split('. ')
                mini_chunk = ""
                for sentence in sentences:
                    if len(mini_chunk + sentence) < max_chunk_size:
                        mini_chunk += sentence + ". "
                    else:
                        if mini_chunk:
                            final_chunks.append(mini_chunk.strip())
                        mini_chunk = sentence + ". "
                if mini_chunk:
                    final_chunks.append(mini_chunk.strip())
            else:
                final_chunks.append(chunk)
        
        return final_chunks
    
    def create_knowledge_entry(self, filename: str, content: str, chunk_index: int = 0, total_chunks: int = 1) -> Dict:
        """Create structured knowledge entry for RAG system"""
        category = self.categorize_file(filename)
        state = self.extract_state_from_filename(filename)
        
        # Create content hash for deduplication
        content_hash = hashlib.md5(content.encode()).hexdigest()[:8]
        
        entry = {
            "id": f"{filename}_{chunk_index}_{content_hash}",
            "title": f"{filename.replace('.txt', '').replace('_', ' ').title()} - Part {chunk_index + 1}" if total_chunks > 1 else filename.replace('.txt', '').replace('_', ' ').title(),
            "content": content,
            "category": category,
            "source": filename,
            "chunk_index": chunk_index,
            "total_chunks": total_chunks,
            "upload_timestamp": datetime.now().isoformat(),
            "metadata": {
                "state": state,
                "content_type": self.determine_content_type(content),
                "priority": self.determine_priority(category),
                "tags": self.generate_tags(content, category, state)
            }
        }
        return entry
    
    def determine_content_type(self, content: str) -> str:
        """Determine specific content type from content analysis"""
        content_lower = content.lower()
        
        if any(term in content_lower for term in ['section', 'code', 'statute', 'law']):
            return 'legal_statute'
        elif any(term in content_lower for term in ['co-parent', 'coparent', 'shared parenting']):
            return 'coparenting_advice'
        elif any(term in content_lower for term in ['custody', 'visitation', 'parenting plan']):
            return 'custody_guidance'
        elif any(term in content_lower for term in ['abuse', 'domestic violence', 'safety']):
            return 'safety_information'
        elif any(term in content_lower for term in ['child support', 'financial', 'expense']):
            return 'financial_guidance'
        else:
            return 'general_guidance'
    
    def determine_priority(self, category: str) -> int:
        """Assign priority level (1=highest, 5=lowest)"""
        priority_map = {
            'coparenting_guidance': 1,
            'state_law': 2,
            'behavioral_psychology': 2,
            'legal_documents': 3,
            'case_studies': 4,
            'general': 5
        }
        return priority_map.get(category, 5)
    
    def generate_tags(self, content: str, category: str, state: Optional[str]) -> List[str]:
        """Generate relevant tags for better searchability"""
        tags = [category]
        
        if state:
            tags.append(state.lower())
        
        content_lower = content.lower()
        
        # Add topic-specific tags
        tag_keywords = {
            'custody': ['custody', 'visitation', 'parenting time'],
            'child_support': ['child support', 'financial', 'expense', 'payment'],
            'communication': ['communication', 'conflict', 'conversation'],
            'safety': ['abuse', 'domestic violence', 'safety', 'protection'],
            'legal': ['court', 'judge', 'legal', 'attorney', 'law'],
            'mediation': ['mediation', 'mediator', 'dispute resolution'],
            'parenting_plan': ['parenting plan', 'agreement', 'schedule']
        }
        
        for tag, keywords in tag_keywords.items():
            if any(keyword in content_lower for keyword in keywords):
                tags.append(tag)
        
        return list(set(tags))  # Remove duplicates
    
    def upload_to_rag_system(self, knowledge_entry: Dict) -> bool:
        """Upload knowledge entry to RAG system"""
        try:
            # Check if there's a specific knowledge upload endpoint
            upload_url = f"{self.base_url}/api/knowledge/upload"
            
            response = self.session.post(
                upload_url,
                json=knowledge_entry,
                headers={'Content-Type': 'application/json'}
            )
            
            if response.status_code == 200:
                print(f"✅ Successfully uploaded: {knowledge_entry['title']}")
                return True
            else:
                print(f"❌ Failed to upload {knowledge_entry['title']}: HTTP {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except requests.RequestException as e:
            print(f"❌ Network error uploading {knowledge_entry['title']}: {str(e)}")
            return False
    
    def process_file(self, filepath: Path) -> int:
        """Process a single file and upload to RAG system"""
        try:
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            if not content.strip():
                print(f"⚠️ Skipping empty file: {filepath.name}")
                return 0
            
            # Chunk the content
            chunks = self.chunk_content(content)
            successful_uploads = 0
            
            print(f"📄 Processing {filepath.name} -> {len(chunks)} chunks")
            
            for i, chunk in enumerate(chunks):
                knowledge_entry = self.create_knowledge_entry(
                    filepath.name, chunk, i, len(chunks)
                )
                
                if self.upload_to_rag_system(knowledge_entry):
                    successful_uploads += 1
                    self.upload_log.append({
                        'file': filepath.name,
                        'chunk': i + 1,
                        'status': 'success',
                        'timestamp': datetime.now().isoformat()
                    })
                else:
                    self.upload_log.append({
                        'file': filepath.name,
                        'chunk': i + 1,
                        'status': 'failed',
                        'timestamp': datetime.now().isoformat()
                    })
                
                # Rate limiting - be respectful to the API
                time.sleep(0.5)
            
            return successful_uploads
            
        except UnicodeDecodeError:
            print(f"⚠️ Skipping binary file: {filepath.name}")
            return 0
        except Exception as e:
            print(f"❌ Error processing {filepath.name}: {str(e)}")
            return 0
    
    def batch_upload(self, file_pattern: str = "*.txt") -> Dict:
        """Batch upload all training files"""
        training_path = Path(self.training_dir)
        
        if not training_path.exists():
            raise FileNotFoundError(f"Training directory not found: {self.training_dir}")
        
        files_to_process = list(training_path.glob(file_pattern))
        
        print(f"🚀 Starting batch upload of {len(files_to_process)} files...")
        print(f"📁 Source directory: {self.training_dir}")
        print(f"🎯 Target RAG system: {self.base_url}")
        print("-" * 60)
        
        stats = {
            'total_files': len(files_to_process),
            'successful_files': 0,
            'total_chunks': 0,
            'successful_chunks': 0,
            'start_time': datetime.now().isoformat()
        }
        
        for filepath in files_to_process:
            successful_chunks = self.process_file(filepath)
            
            if successful_chunks > 0:
                stats['successful_files'] += 1
            
            stats['total_chunks'] += len(self.chunk_content(filepath.read_text(encoding='utf-8', errors='ignore')))
            stats['successful_chunks'] += successful_chunks
            
            print(f"   📊 File complete: {successful_chunks} chunks uploaded")
            print()
        
        stats['end_time'] = datetime.now().isoformat()
        
        # Save upload log
        log_file = f"upload_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(log_file, 'w') as f:
            json.dump({
                'stats': stats,
                'log': self.upload_log
            }, f, indent=2)
        
        print("=" * 60)
        print("📊 UPLOAD SUMMARY")
        print("=" * 60)
        print(f"Files processed: {stats['successful_files']}/{stats['total_files']}")
        print(f"Chunks uploaded: {stats['successful_chunks']}/{stats['total_chunks']}")
        print(f"Success rate: {(stats['successful_chunks']/stats['total_chunks']*100):.1f}%")
        print(f"Log saved to: {log_file}")
        print("=" * 60)
        
        return stats

def main():
    """Main execution function"""
    uploader = GCPKnowledgeUploader()
    
    try:
        # Upload all text files
        stats = uploader.batch_upload("*.txt")
        
        if stats['successful_chunks'] > 0:
            print("🎉 Knowledge base upload completed successfully!")
            print(f"Your RAG system now has access to {stats['successful_chunks']} new knowledge chunks")
        else:
            print("⚠️ No content was successfully uploaded. Check your RAG endpoint configuration.")
            
    except Exception as e:
        print(f"❌ Upload failed: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    main()