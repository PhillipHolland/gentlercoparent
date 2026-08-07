#!/usr/bin/env python3
"""
Gentler Coparent Knowledge Base Population Script
Since the RAG system doesn't have a direct upload endpoint, this script
processes training content and creates a comprehensive knowledge summary 
that can be manually integrated into the knowledge base.
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional
import hashlib
from datetime import datetime

class KnowledgeProcessor:
    def __init__(self):
        self.training_dir = "/Users/phillipholland/Documents/GCP_TRAINING"
        self.output_dir = "/Users/phillipholland/Documents/GCP-xcodebackups/1.0.12/Gentler Coparent/processed_knowledge"
        
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
    
    def chunk_content(self, content: str, max_chunk_size: int = 2000) -> List[str]:
        """Split content into manageable chunks"""
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
        
        return chunks
    
    def extract_key_concepts(self, content: str, category: str) -> List[str]:
        """Extract key legal and co-parenting concepts from content"""
        content_lower = content.lower()
        concepts = []
        
        # Legal concepts
        legal_terms = [
            'custody', 'visitation', 'parenting time', 'child support', 'modification',
            'contempt', 'enforcement', 'best interests', 'substantial change',
            'parenting plan', 'joint custody', 'sole custody', 'supervised visitation'
        ]
        
        # Co-parenting concepts
        coparenting_terms = [
            'communication', 'conflict resolution', 'parallel parenting',
            'co-parenting', 'shared parenting', 'boundaries', 'consistency',
            'child-focused', 'emotional abuse', 'alienation', 'mediation'
        ]
        
        # Check for legal terms
        for term in legal_terms:
            if term in content_lower:
                concepts.append(f"Legal: {term}")
        
        # Check for co-parenting terms
        for term in coparenting_terms:
            if term in content_lower:
                concepts.append(f"Co-parenting: {term}")
        
        return list(set(concepts))  # Remove duplicates
    
    def create_knowledge_summary(self, filepath: Path) -> Dict:
        """Create a comprehensive summary of file content"""
        try:
            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
            
            if not content.strip():
                return None
            
            category = self.categorize_file(filepath.name)
            state = self.extract_state_from_filename(filepath.name)
            chunks = self.chunk_content(content)
            concepts = self.extract_key_concepts(content, category)
            
            # Create structured summary
            summary = {
                "filename": filepath.name,
                "category": category,
                "state": state,
                "total_chunks": len(chunks),
                "word_count": len(content.split()),
                "key_concepts": concepts,
                "chunks": []
            }
            
            # Process each chunk
            for i, chunk in enumerate(chunks):
                chunk_summary = {
                    "index": i + 1,
                    "content": chunk,
                    "word_count": len(chunk.split()),
                    "key_phrases": self.extract_key_phrases(chunk),
                    "content_type": self.determine_content_type(chunk)
                }
                summary["chunks"].append(chunk_summary)
            
            return summary
            
        except Exception as e:
            print(f"❌ Error processing {filepath.name}: {str(e)}")
            return None
    
    def extract_key_phrases(self, text: str) -> List[str]:
        """Extract important phrases from text chunk"""
        phrases = []
        text_lower = text.lower()
        
        # Look for numbered sections
        import re
        sections = re.findall(r'\d+\.\s*([^.]+)', text)
        for section in sections[:3]:  # Take first 3 sections
            phrases.append(f"Section: {section.strip()}")
        
        # Look for definitions
        definitions = re.findall(r'"([^"]+)"', text)
        for definition in definitions[:2]:  # Take first 2 definitions
            phrases.append(f"Definition: {definition}")
        
        # Look for important statements
        if 'shall' in text_lower:
            phrases.append("Contains legal requirements")
        if 'best interests' in text_lower:
            phrases.append("Best interests standard")
        if 'modification' in text_lower:
            phrases.append("Modification procedures")
        
        return phrases
    
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
    
    def process_all_files(self) -> Dict:
        """Process all training files and create comprehensive knowledge base"""
        training_path = Path(self.training_dir)
        output_path = Path(self.output_dir)
        output_path.mkdir(exist_ok=True)
        
        if not training_path.exists():
            raise FileNotFoundError(f"Training directory not found: {self.training_dir}")
        
        files_to_process = list(training_path.glob("*.txt"))
        
        print(f"🚀 Processing {len(files_to_process)} files for knowledge extraction...")
        print(f"📁 Source directory: {self.training_dir}")
        print(f"📁 Output directory: {self.output_dir}")
        print("-" * 60)
        
        knowledge_base = {
            "metadata": {
                "created": datetime.now().isoformat(),
                "total_files": len(files_to_process),
                "categories": list(self.categories.keys())
            },
            "files": {},
            "category_summaries": {},
            "state_summaries": {}
        }
        
        # Process each file
        processed_count = 0
        total_chunks = 0
        
        for filepath in files_to_process:
            print(f"📄 Processing {filepath.name}...")
            
            summary = self.create_knowledge_summary(filepath)
            if summary:
                knowledge_base["files"][filepath.name] = summary
                total_chunks += summary["total_chunks"]
                processed_count += 1
                
                # Update category summaries
                category = summary["category"]
                if category not in knowledge_base["category_summaries"]:
                    knowledge_base["category_summaries"][category] = {
                        "files": [],
                        "total_chunks": 0,
                        "key_concepts": set()
                    }
                
                knowledge_base["category_summaries"][category]["files"].append(filepath.name)
                knowledge_base["category_summaries"][category]["total_chunks"] += summary["total_chunks"]
                knowledge_base["category_summaries"][category]["key_concepts"].update(summary["key_concepts"])
                
                # Update state summaries
                if summary["state"]:
                    state = summary["state"]
                    if state not in knowledge_base["state_summaries"]:
                        knowledge_base["state_summaries"][state] = {
                            "files": [],
                            "total_chunks": 0
                        }
                    knowledge_base["state_summaries"][state]["files"].append(filepath.name)
                    knowledge_base["state_summaries"][state]["total_chunks"] += summary["total_chunks"]
        
        # Convert sets to lists for JSON serialization
        for category in knowledge_base["category_summaries"]:
            knowledge_base["category_summaries"][category]["key_concepts"] = \
                list(knowledge_base["category_summaries"][category]["key_concepts"])
        
        # Update metadata
        knowledge_base["metadata"]["processed_files"] = processed_count
        knowledge_base["metadata"]["total_chunks"] = total_chunks
        
        # Save comprehensive knowledge base
        kb_file = output_path / "knowledge_base_complete.json"
        with open(kb_file, 'w') as f:
            json.dump(knowledge_base, f, indent=2, ensure_ascii=False)
        
        # Create category-specific files
        for category, data in knowledge_base["category_summaries"].items():
            category_file = output_path / f"knowledge_{category}.json"
            category_data = {
                "category": category,
                "files": data["files"],
                "total_chunks": data["total_chunks"],
                "key_concepts": data["key_concepts"],
                "detailed_content": {}
            }
            
            # Add detailed content for this category
            for filename in data["files"]:
                if filename in knowledge_base["files"]:
                    category_data["detailed_content"][filename] = knowledge_base["files"][filename]
            
            with open(category_file, 'w') as f:
                json.dump(category_data, f, indent=2, ensure_ascii=False)
        
        # Create implementation guide
        self.create_implementation_guide(output_path, knowledge_base)
        
        print("=" * 60)
        print("📊 KNOWLEDGE PROCESSING SUMMARY")
        print("=" * 60)
        print(f"Files processed: {processed_count}/{len(files_to_process)}")
        print(f"Total content chunks: {total_chunks}")
        print(f"Categories: {len(knowledge_base['category_summaries'])}")
        print(f"States covered: {len(knowledge_base['state_summaries'])}")
        print(f"Output directory: {output_path}")
        print("=" * 60)
        
        return knowledge_base
    
    def create_implementation_guide(self, output_path: Path, knowledge_base: Dict):
        """Create a guide for implementing the knowledge base"""
        guide_content = f"""# Gentler Coparent Knowledge Base Implementation Guide

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary
- **Total Files Processed**: {knowledge_base['metadata']['processed_files']}
- **Total Content Chunks**: {knowledge_base['metadata']['total_chunks']}
- **Categories**: {len(knowledge_base['category_summaries'])}
- **States Covered**: {len(knowledge_base['state_summaries'])}

## Categories Overview
"""
        
        for category, data in knowledge_base["category_summaries"].items():
            guide_content += f"""
### {category.replace('_', ' ').title()}
- **Files**: {len(data['files'])}
- **Chunks**: {data['total_chunks']}
- **Key Concepts**: {len(data['key_concepts'])}
- **Files**: {', '.join(data['files'][:5])}{'...' if len(data['files']) > 5 else ''}
"""
        
        guide_content += f"""

## Implementation Options

### Option 1: Manual Integration
1. Review the processed knowledge files in: `{output_path}`
2. Use the category-specific JSON files to understand content structure
3. Manually integrate key content into your existing RAG system

### Option 2: Enhanced Chat Integration
Since your system uses `/api/enhanced-chat`, you could:
1. Modify the endpoint to accept knowledge base updates
2. Use the structured data to improve retrieval quality
3. Implement batch processing for large content volumes

### Option 3: Vector Database Population
1. Use the chunked content to populate a vector database
2. Each chunk includes metadata for better retrieval
3. Implement semantic search across categorized content

## Next Steps
1. Review `knowledge_base_complete.json` for full structure
2. Check category-specific files for targeted content
3. Consider which implementation approach works best for your system
4. Test retrieval quality with sample queries

## Files Generated
- `knowledge_base_complete.json` - Complete knowledge base
- `knowledge_*.json` - Category-specific files
- `implementation_guide.md` - This guide

The knowledge base is now ready for integration into your RAG system!
"""
        
        guide_file = output_path / "implementation_guide.md"
        with open(guide_file, 'w') as f:
            f.write(guide_content)

def main():
    """Main execution function"""
    processor = KnowledgeProcessor()
    
    try:
        knowledge_base = processor.process_all_files()
        
        print("🎉 Knowledge base processing completed successfully!")
        print(f"📁 Check the processed_knowledge directory for implementation files")
        print(f"📋 Review implementation_guide.md for next steps")
        
    except Exception as e:
        print(f"❌ Processing failed: {str(e)}")
        return False
    
    return True

if __name__ == "__main__":
    main()