#!/usr/bin/env python3
"""
猜数字游戏
一个简单有趣的互动游戏
"""

import random


def guess_number_game():
    """猜数字游戏主函数"""
    print("=" * 50)
    print("🎮 欢迎来到猜数字游戏！")
    print("=" * 50)
    print("我已经想好了一个 1 到 100 之间的数字")
    print("你能猜中它吗？\n")
    
    # 生成随机数
    secret_number = random.randint(1, 100)
    attempts = 0
    max_attempts = 10
    
    while attempts < max_attempts:
        try:
            # 获取用户输入
            guess = int(input(f"第 {attempts + 1} 次尝试 (剩余 {max_attempts - attempts} 次): "))
            attempts += 1
            
            # 判断猜测结果
            if guess < 1 or guess > 100:
                print("❌ 请输入 1 到 100 之间的数字！\n")
                continue
            
            if guess < secret_number:
                print("📈 太小了！再试试更大的数字\n")
            elif guess > secret_number:
                print("📉 太大了！再试试更小的数字\n")
            else:
                print(f"\n🎉 恭喜你！猜对了！")
                print(f"✨ 正确答案是: {secret_number}")
                print(f"🏆 你用了 {attempts} 次尝试")
                
                # 评价表现
                if attempts <= 3:
                    print("💯 太厉害了！你是猜数字高手！")
                elif attempts <= 6:
                    print("👍 不错的表现！")
                else:
                    print("😊 继续加油！")
                return
        
        except ValueError:
            print("❌ 请输入有效的数字！\n")
            continue
    
    # 游戏失败
    print(f"\n😢 很遗憾，你用完了所有 {max_attempts} 次机会")
    print(f"💡 正确答案是: {secret_number}")
    print("下次再来挑战吧！")


def main():
    """主函数"""
    while True:
        guess_number_game()
        
        # 询问是否继续
        play_again = input("\n要再玩一局吗？(y/n): ").lower()
        if play_again != 'y' and play_again != 'yes':
            print("\n👋 谢谢游玩！再见！")
            break
        print("\n")


if __name__ == "__main__":
    main()
