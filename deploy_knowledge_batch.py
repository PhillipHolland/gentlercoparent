#!/usr/bin/env python3
"""
Deploy processed knowledge to enhanced Vercel API in batches
This script uploads the structured knowledge base in smaller chunks to avoid payload size limits
"""

import json
import requests
import time
from pathlib import Path

class BatchKnowledgeDeployer:
    def __init__(self):
        self.api_url = "https://gentler-coparent-simple-rag.vercel.app/api/enhanced-chat"
        self.knowledge_dir = "/Users/phillipholland/Documents/GCP-xcodebackups/1.0.12/Gentler Coparent/processed_knowledge"
        self.session = requests.Session()
        self.session.timeout = 60
        self.batch_size = 5  # Upload 5 files at a time
    
    def load_knowledge_base(self):
        """Load the complete processed knowledge base"""
        kb_file = Path(self.knowledge_dir) / "knowledge_base_complete.json"
        
        if not kb_file.exists():
            raise FileNotFoundError(f"Knowledge base file not found: {kb_file}")
        
        with open(kb_file, 'r') as f:
            return json.load(f)
    
    def create_batches(self, knowledge_base):
        """Split knowledge base into smaller batches"""
        files_dict = knowledge_base.get('files', {})
        file_items = list(files_dict.items())
        
        batches = []
        for i in range(0, len(file_items), self.batch_size):
            batch_files = dict(file_items[i:i + self.batch_size])
            
            batch = {
                "metadata": {
                    "batch_number": i // self.batch_size + 1,
                    "total_batches": (len(file_items) + self.batch_size - 1) // self.batch_size,
                    "files_in_batch": len(batch_files)
                },
                "files": batch_files
            }
            batches.append(batch)
        
        return batches
    
    def test_api_connectivity(self):
        """Test if the API is accessible"""
        try:
            response = self.session.get(self.api_url)
            print(f"📡 API Status: {response.status_code}")
            if response.status_code == 200:
                result = response.json()
                print(f"📊 Current knowledge chunks: {result.get('totalChunks', 0)}")
            return response.status_code == 200
        except Exception as e:
            print(f"❌ API connectivity test failed: {e}")
            return False
    
    def upload_batch(self, batch_data, batch_num, total_batches, overwrite=False):
        """Upload a single batch of knowledge"""
        print(f"\n📦 Uploading batch {batch_num}/{total_batches} ({batch_data['metadata']['files_in_batch']} files)...")
        
        upload_data = {
            "knowledgeData": batch_data,
            "category": f"batch_{batch_num}",
            "overwrite": overwrite and batch_num == 1  # Only overwrite on first batch
        }
        
        try:
            start_time = time.time()
            
            response = self.session.put(
                self.api_url,
                json=upload_data,
                headers={'Content-Type': 'application/json'}
            )
            
            upload_time = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                chunks_added = result.get('chunksAdded', 0)
                total_chunks = result.get('totalChunks', 0)
                
                print(f"   ✅ Batch {batch_num} uploaded successfully!")
                print(f"   📈 Chunks added: {chunks_added}")
                print(f"   📚 Total chunks now: {total_chunks}")
                print(f"   ⏱️ Upload time: {upload_time:.2f}s")
                
                return True, chunks_added, total_chunks
            else:
                error_msg = response.text
                print(f"   ❌ Batch {batch_num} failed with status {response.status_code}")
                print(f"   Response: {error_msg[:200]}...")
                return False, 0, 0
                
        except requests.RequestException as e:
            print(f"   ❌ Network error uploading batch {batch_num}: {e}")
            return False, 0, 0
        except Exception as e:
            print(f"   ❌ Unexpected error uploading batch {batch_num}: {e}")
            return False, 0, 0
    
    def deploy_in_batches(self, overwrite=True):
        """Deploy knowledge base in smaller batches"""
        print("🚀 Starting batch knowledge base deployment...")
        
        # Test connectivity first
        if not self.test_api_connectivity():
            print("❌ Cannot connect to API. Deployment aborted.")
            return False
        
        # Load and prepare knowledge base
        print("📚 Loading processed knowledge base...")
        try:
            knowledge_base = self.load_knowledge_base()
        except Exception as e:
            print(f"❌ Failed to load knowledge base: {e}")
            return False
        
        # Create batches
        print(f"📦 Creating batches of {self.batch_size} files each...")
        batches = self.create_batches(knowledge_base)
        
        print(f"📊 Total files: {knowledge_base['metadata']['total_files']}")
        print(f"📊 Total chunks: {knowledge_base['metadata']['total_chunks']}")
        print(f"📦 Number of batches: {len(batches)}")
        
        # Upload batches
        successful_batches = 0
        total_chunks_uploaded = 0
        failed_batches = []
        
        for i, batch in enumerate(batches, 1):
            success, chunks_added, total_chunks = self.upload_batch(
                batch, i, len(batches), overwrite and i == 1
            )
            
            if success:
                successful_batches += 1
                total_chunks_uploaded += chunks_added
            else:
                failed_batches.append(i)
            
            # Rate limiting between batches
            if i < len(batches):
                time.sleep(2)
        
        # Final status
        print("\n" + "=" * 60)
        print("📊 BATCH DEPLOYMENT SUMMARY")
        print("=" * 60)
        print(f"Successful batches: {successful_batches}/{len(batches)}")
        print(f"Total chunks uploaded: {total_chunks_uploaded}")
        
        if failed_batches:
            print(f"Failed batches: {failed_batches}")
            print("❌ Some batches failed - partial deployment completed")
            return False
        else:
            print("✅ All batches uploaded successfully!")
            return True
    
    def test_enhanced_retrieval(self):
        """Test the enhanced retrieval with sample queries"""
        test_queries = [
            {
                "message": "What are the custody modification requirements in Texas?",
                "userProfile": {"state": "Texas"}
            },
            {
                "message": "How should I handle communication conflicts with my co-parent?",
                "userProfile": {}
            },
            {
                "message": "What should I do if my ex is not following the visitation schedule in California?",
                "userProfile": {"state": "California"}
            }
        ]
        
        print("\n🧪 Testing enhanced retrieval with uploaded knowledge...")
        
        for i, query in enumerate(test_queries, 1):
            print(f"\n📝 Test Query {i}: {query['message'][:50]}...")
            
            try:
                response = self.session.post(
                    self.api_url,
                    json=query,
                    headers={'Content-Type': 'application/json'}
                )
                
                if response.status_code == 200:
                    result = response.json()
                    knowledge_used = result.get('knowledgeUsed', [])
                    confidence = result.get('confidenceScore', 0)
                    
                    print(f"   ✅ Success!")
                    print(f"   📚 Knowledge sources: {len(knowledge_used)}")
                    print(f"   🎯 Confidence: {confidence:.2f}")
                    if knowledge_used:
                        print(f"   📄 Top source: {knowledge_used[0]}")
                else:
                    print(f"   ❌ Failed with status {response.status_code}")
                    
            except Exception as e:
                print(f"   ❌ Error: {e}")
            
            time.sleep(1)  # Rate limiting
    
    def deploy_and_test(self, overwrite=True, run_tests=True):
        """Complete deployment and testing workflow"""
        print("=" * 60)
        print("🚀 GENTLER COPARENT BATCH KNOWLEDGE DEPLOYMENT")
        print("=" * 60)
        
        # Upload knowledge base in batches
        upload_success = self.deploy_in_batches(overwrite)
        
        if upload_success and run_tests:
            # Test the enhanced system
            self.test_enhanced_retrieval()
        
        print("\n" + "=" * 60)
        if upload_success:
            print("🎉 BATCH DEPLOYMENT COMPLETED SUCCESSFULLY!")
            print("Your RAG system now has access to comprehensive co-parenting knowledge!")
        else:
            print("❌ BATCH DEPLOYMENT PARTIALLY FAILED")
            print("Some knowledge was uploaded, but not all batches succeeded.")
        print("=" * 60)
        
        return upload_success

def main():
    """Main execution function"""
    deployer = BatchKnowledgeDeployer()
    
    try:
        # Deploy with full testing
        success = deployer.deploy_and_test(overwrite=True, run_tests=True)
        return success
        
    except Exception as e:
        print(f"❌ Deployment script failed: {e}")
        return False

if __name__ == "__main__":
    main()